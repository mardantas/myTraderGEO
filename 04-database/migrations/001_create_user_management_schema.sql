-- =====================================================
-- Migration: 001_create_user_management_schema.sql
-- Epic: EPIC-01-A - User Management
-- Description: Schema para User Management Bounded Context
-- Database: PostgreSQL 14+
-- Author: DBA Agent
-- Date: 2025-10-26
-- =====================================================

-- =====================================================
-- TABLE: SubscriptionPlans
-- Aggregate Root: SubscriptionPlan
-- =====================================================
CREATE TABLE SubscriptionPlans (
    -- Primary Key
    Id UUID PRIMARY KEY,

    -- Core Properties
    Name VARCHAR(50) NOT NULL,
    PriceMonthlyAmount DECIMAL(10,2) NOT NULL,
    PriceMonthlyC

 VARCHAR(3) NOT NULL DEFAULT 'BRL',
    PriceAnnualAmount DECIMAL(10,2) NOT NULL,
    PriceAnnualCurrency VARCHAR(3) NOT NULL DEFAULT 'BRL',
    AnnualDiscountPercent DECIMAL(5,4) NOT NULL, -- 0.2000 = 20%

    -- Limits
    StrategyLimit INT NOT NULL,

    -- Features (embedded as separate columns for query performance)
    FeatureRealtimeData BOOLEAN NOT NULL DEFAULT FALSE,
    FeatureAdvancedAlerts BOOLEAN NOT NULL DEFAULT FALSE,
    FeatureConsultingTools BOOLEAN NOT NULL DEFAULT FALSE,
    FeatureCommunityAccess BOOLEAN NOT NULL DEFAULT TRUE,

    -- Status
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,

    -- Audit
    CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP NULL,

    -- Constraints
    CONSTRAINT CK_SubscriptionPlan_PriceMonthly_NonNegative
        CHECK (PriceMonthlyAmount >= 0),
    CONSTRAINT CK_SubscriptionPlan_PriceAnnual_NonNegative
        CHECK (PriceAnnualAmount >= 0),
    CONSTRAINT CK_SubscriptionPlan_AnnualDiscount_Valid
        CHECK (AnnualDiscountPercent >= 0 AND AnnualDiscountPercent <= 1),
    CONSTRAINT CK_SubscriptionPlan_StrategyLimit_Positive
        CHECK (StrategyLimit > 0),
    CONSTRAINT CK_SubscriptionPlan_AnnualPrice_Discounted
        CHECK (PriceMonthlyAmount = 0 OR PriceAnnualAmount < (PriceMonthlyAmount * 12))
);

-- Indexes for SubscriptionPlans
CREATE UNIQUE INDEX UX_SubscriptionPlans_Name ON SubscriptionPlans(Name);
CREATE INDEX IX_SubscriptionPlans_IsActive ON SubscriptionPlans(IsActive);
CREATE INDEX IX_SubscriptionPlans_CreatedAt ON SubscriptionPlans(CreatedAt DESC);

-- =====================================================
-- TABLE: SystemConfigs
-- Aggregate Root: SystemConfig (Singleton)
-- =====================================================
CREATE TABLE SystemConfigs (
    -- Primary Key (Singleton - sempre 00000000-0000-0000-0000-000000000001)
    Id UUID PRIMARY KEY,

    -- Taxas Operacionais
    BrokerCommissionRate DECIMAL(10,8) NOT NULL, -- 0.00000000 = 0%
    B3EmolumentRate DECIMAL(10,8) NOT NULL,      -- 0.00032500 = 0.0325%
    SettlementFeeRate DECIMAL(10,8) NOT NULL,    -- 0.00027500 = 0.0275%
    IssRate DECIMAL(10,8) NOT NULL,              -- 0.05000000 = 5%

    -- Impostos
    IncomeTaxRate DECIMAL(10,8) NOT NULL,        -- 0.15000000 = 15%
    DayTradeIncomeTaxRate DECIMAL(10,8) NOT NULL,-- 0.20000000 = 20%

    -- Limites Globais
    MaxOpenStrategiesPerUser INT NOT NULL,
    MaxStrategiesInTemplate INT NOT NULL,

    -- Audit
    UpdatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedBy UUID NOT NULL, -- FK to Users.Id (Admin who updated)

    -- Constraints
    CONSTRAINT CK_SystemConfig_BrokerCommissionRate_Valid
        CHECK (BrokerCommissionRate >= 0 AND BrokerCommissionRate <= 1),
    CONSTRAINT CK_SystemConfig_B3EmolumentRate_Valid
        CHECK (B3EmolumentRate >= 0 AND B3EmolumentRate <= 1),
    CONSTRAINT CK_SystemConfig_SettlementFeeRate_Valid
        CHECK (SettlementFeeRate >= 0 AND SettlementFeeRate <= 1),
    CONSTRAINT CK_SystemConfig_IssRate_Valid
        CHECK (IssRate >= 0 AND IssRate <= 1),
    CONSTRAINT CK_SystemConfig_IncomeTaxRate_Valid
        CHECK (IncomeTaxRate >= 0 AND IncomeTaxRate <= 1),
    CONSTRAINT CK_SystemConfig_DayTradeIncomeTaxRate_Valid
        CHECK (DayTradeIncomeTaxRate >= 0 AND DayTradeIncomeTaxRate <= 1),
    CONSTRAINT CK_SystemConfig_MaxOpenStrategies_Positive
        CHECK (MaxOpenStrategiesPerUser > 0),
    CONSTRAINT CK_SystemConfig_MaxStrategiesInTemplate_Positive
        CHECK (MaxStrategiesInTemplate > 0)
);

-- =====================================================
-- TABLE: Users
-- Aggregate Root: User
-- =====================================================
CREATE TABLE Users (
    -- Primary Key
    Id UUID PRIMARY KEY,

    -- Authentication
    Email VARCHAR(255) NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,

    -- Profile
    FullName VARCHAR(255) NOT NULL,
    DisplayName VARCHAR(30) NOT NULL,

    -- Phone (for WhatsApp, 2FA, recovery)
    PhoneCountryCode VARCHAR(5) NULL, -- +55, +1, etc
    PhoneNumber VARCHAR(15) NULL,     -- digits only
    IsPhoneVerified BOOLEAN NOT NULL DEFAULT FALSE,
    PhoneVerifiedAt TIMESTAMP NULL,

    -- Role & Status
    Role VARCHAR(20) NOT NULL, -- Trader, Moderator, Administrator
    Status VARCHAR(20) NOT NULL DEFAULT 'Active', -- Active, Suspended, Deleted

    -- Risk Profile (nullable for Admin/Moderator)
    RiskProfile VARCHAR(20) NULL, -- Conservador, Moderado, Agressivo

    -- Subscription (nullable for Admin/Moderator)
    SubscriptionPlanId UUID NULL,
    BillingPeriod INT NULL, -- 1=Monthly, 12=Annual (enum value)

    -- Plan Override (JSON for flexibility)
    -- Structure: { StrategyLimitOverride?, FeaturesOverride?, ExpiresAt?, Reason, GrantedBy, GrantedAt }
    PlanOverride JSONB NULL,

    -- Custom Trading Fees (JSON)
    -- Structure: { BrokerCommissionRate?, B3EmolumentRate?, SettlementFeeRate?, IncomeTaxRate?, DayTradeIncomeTaxRate? }
    CustomFees JSONB NULL,

    -- Audit
    CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastLoginAt TIMESTAMP NULL,

    -- Constraints
    CONSTRAINT CK_User_DisplayName_Length
        CHECK (LENGTH(DisplayName) >= 2 AND LENGTH(DisplayName) <= 30),
    CONSTRAINT CK_User_Role_Valid
        CHECK (Role IN ('Trader', 'Moderator', 'Administrator')),
    CONSTRAINT CK_User_Status_Valid
        CHECK (Status IN ('Active', 'Suspended', 'Deleted')),
    CONSTRAINT CK_User_RiskProfile_Valid
        CHECK (RiskProfile IS NULL OR RiskProfile IN ('Conservador', 'Moderado', 'Agressivo')),
    CONSTRAINT CK_User_BillingPeriod_Valid
        CHECK (BillingPeriod IS NULL OR BillingPeriod IN (1, 12)),
    CONSTRAINT CK_User_Trader_MustHave_Subscription
        CHECK (Role != 'Trader' OR (SubscriptionPlanId IS NOT NULL AND BillingPeriod IS NOT NULL)),
    CONSTRAINT CK_User_Trader_MustHave_RiskProfile
        CHECK (Role != 'Trader' OR RiskProfile IS NOT NULL),
    CONSTRAINT CK_User_AdminModerator_NoSubscription
        CHECK (Role = 'Trader' OR (SubscriptionPlanId IS NULL AND BillingPeriod IS NULL)),
    CONSTRAINT CK_User_Phone_BothOrNone
        CHECK ((PhoneCountryCode IS NULL AND PhoneNumber IS NULL) OR
               (PhoneCountryCode IS NOT NULL AND PhoneNumber IS NOT NULL)),

    -- Foreign Keys
    CONSTRAINT FK_Users_SubscriptionPlanId
        FOREIGN KEY (SubscriptionPlanId) REFERENCES SubscriptionPlans(Id)
);

-- Indexes for Users
CREATE UNIQUE INDEX UX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_Role ON Users(Role);
CREATE INDEX IX_Users_Status ON Users(Status);
CREATE INDEX IX_Users_SubscriptionPlanId ON Users(SubscriptionPlanId) WHERE SubscriptionPlanId IS NOT NULL;
CREATE INDEX IX_Users_CreatedAt ON Users(CreatedAt DESC);
CREATE INDEX IX_Users_LastLoginAt ON Users(LastLoginAt DESC) WHERE LastLoginAt IS NOT NULL;

-- GIN index for JSONB columns (for querying inside JSON)
CREATE INDEX IX_Users_PlanOverride_GIN ON Users USING GIN(PlanOverride) WHERE PlanOverride IS NOT NULL;
CREATE INDEX IX_Users_CustomFees_GIN ON Users USING GIN(CustomFees) WHERE CustomFees IS NOT NULL;

-- =====================================================
-- FOREIGN KEY: SystemConfigs -> Users
-- (Added after Users table is created)
-- =====================================================
ALTER TABLE SystemConfigs
    ADD CONSTRAINT FK_SystemConfigs_UpdatedBy
    FOREIGN KEY (UpdatedBy) REFERENCES Users(Id);

-- =====================================================
-- COMMENTS (Documentation)
-- =====================================================
COMMENT ON TABLE SubscriptionPlans IS 'Aggregate Root: SubscriptionPlan - Planos de assinatura (Básico, Pleno, Consultor)';
COMMENT ON TABLE SystemConfigs IS 'Aggregate Root: SystemConfig - Configurações globais do sistema (Singleton)';
COMMENT ON TABLE Users IS 'Aggregate Root: User - Gerenciamento de usuários, autenticação e perfil';

COMMENT ON COLUMN Users.PlanOverride IS 'JSON: UserPlanOverride - Override temporário de plano (VIP, trial, beta, staff)';
COMMENT ON COLUMN Users.CustomFees IS 'JSON: TradingFees - Taxas customizadas por usuário (null = usar SystemConfig)';
COMMENT ON COLUMN Users.BillingPeriod IS 'Enum: 1=Monthly, 12=Annual';
COMMENT ON COLUMN Users.PhoneCountryCode IS 'Formato: +CountryCode (ex: +55 para Brasil)';
COMMENT ON COLUMN Users.PhoneNumber IS 'Formato: Apenas dígitos (ex: 11987654321)';

COMMENT ON COLUMN SubscriptionPlans.AnnualDiscountPercent IS 'Decimal: 0.20 = 20% de desconto';
COMMENT ON COLUMN SubscriptionPlans.StrategyLimit IS 'Limite de estratégias simultâneas para este plano';

COMMENT ON COLUMN SystemConfigs.BrokerCommissionRate IS 'Taxa de corretagem (0.0 = 0% - maioria das corretoras)';
COMMENT ON COLUMN SystemConfigs.B3EmolumentRate IS 'Taxa de emolumentos B3 (0.000325 = 0.0325%)';
COMMENT ON COLUMN SystemConfigs.SettlementFeeRate IS 'Taxa de liquidação (0.000275 = 0.0275%)';
COMMENT ON COLUMN SystemConfigs.IssRate IS 'ISS sobre emolumentos (0.05 = 5%)';
COMMENT ON COLUMN SystemConfigs.IncomeTaxRate IS 'IR sobre lucro swing-trade (0.15 = 15%)';
COMMENT ON COLUMN SystemConfigs.DayTradeIncomeTaxRate IS 'IR sobre lucro day-trade (0.20 = 20%)';
