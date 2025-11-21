-- =====================================================
-- Seed: 001_seed_user_management_defaults.sql
-- Epic: EPIC-01-A - User Management
-- Description: Dados iniciais para User Management BC
-- Database: PostgreSQL 14+
-- Author: DBA Agent
-- Date: 2025-10-26
-- =====================================================

-- =====================================================
-- SEED: SubscriptionPlans (3 planos padrão)
-- =====================================================

-- Plano Básico (Free)
INSERT INTO SubscriptionPlans (
    Name,
    PriceMonthlyAmount,
    PriceMonthlyCurrency,
    PriceAnnualAmount,
    PriceAnnualCurrency,
    AnnualDiscountPercent,
    StrategyLimit,
    FeatureRealtimeData,
    FeatureAdvancedAlerts,
    FeatureConsultingTools,
    FeatureCommunityAccess,
    IsActive,
    CreatedAt
) VALUES (
    'Básico',
    0.00,     -- Free
    'BRL',
    0.00,     -- Free
    'BRL',
    0.0000,   -- Sem desconto (free)
    1,        -- Limite: 1 estratégia
    FALSE,    -- Sem realtime data
    FALSE,    -- Sem alertas avançados
    FALSE,    -- Sem ferramentas de consultoria
    TRUE,     -- Acesso à comunidade
    TRUE,     -- Ativo
    CURRENT_TIMESTAMP
) ON CONFLICT (Name) DO NOTHING;

-- Plano Pleno (Paid - R$ 49.90/mês)
INSERT INTO SubscriptionPlans (
    Name,
    PriceMonthlyAmount,
    PriceMonthlyCurrency,
    PriceAnnualAmount,
    PriceAnnualCurrency,
    AnnualDiscountPercent,
    StrategyLimit,
    FeatureRealtimeData,
    FeatureAdvancedAlerts,
    FeatureConsultingTools,
    FeatureCommunityAccess,
    IsActive,
    CreatedAt
) VALUES (
    'Pleno',
    49.90,    -- R$ 49,90/mês
    'BRL',
    479.04,   -- R$ 479,04/ano (20% desconto = 10 meses)
    'BRL',
    0.2000,   -- 20% desconto anual
    999,      -- Limite: ilimitado (representado por 999)
    TRUE,     -- Realtime data
    TRUE,     -- Alertas avançados
    FALSE,    -- Sem ferramentas de consultoria
    TRUE,     -- Acesso à comunidade
    TRUE,     -- Ativo
    CURRENT_TIMESTAMP
) ON CONFLICT (Name) DO NOTHING;

-- Plano Consultor (Premium - R$ 99.90/mês)
INSERT INTO SubscriptionPlans (
    Name,
    PriceMonthlyAmount,
    PriceMonthlyCurrency,
    PriceAnnualAmount,
    PriceAnnualCurrency,
    AnnualDiscountPercent,
    StrategyLimit,
    FeatureRealtimeData,
    FeatureAdvancedAlerts,
    FeatureConsultingTools,
    FeatureCommunityAccess,
    IsActive,
    CreatedAt
) VALUES (
    'Consultor',
    99.90,    -- R$ 99,90/mês
    'BRL',
    959.04,   -- R$ 959,04/ano (20% desconto = 10 meses)
    'BRL',
    0.2000,   -- 20% desconto anual
    999,      -- Limite: ilimitado (representado por 999)
    TRUE,     -- Realtime data
    TRUE,     -- Alertas avançados
    TRUE,     -- Ferramentas de consultoria
    TRUE,     -- Acesso à comunidade
    TRUE,     -- Ativo
    CURRENT_TIMESTAMP
) ON CONFLICT (Name) DO NOTHING;

-- =====================================================
-- SEED: SystemConfig (Singleton - configuração global)
-- =====================================================

-- Criar usuário System temporário para UpdatedBy
-- (Será substituído pelo primeiro Administrator criado)
INSERT INTO Users (
    Id,
    Email,
    PasswordHash,
    FullName,
    DisplayName,
    PhoneCountryCode,
    PhoneNumber,
    IsPhoneVerified,
    PhoneVerifiedAt,
    Role,
    Status,
    RiskProfile,
    SubscriptionPlanId,
    BillingPeriod,
    PlanOverride,
    CustomFees,
    CreatedAt,
    LastLoginAt
) VALUES (
    '00000000-0000-0000-0000-000000000000', -- System User
    'system@mytradergeo.com',
    '$2a$11$SYSTEM_HASH_PLACEHOLDER_DO_NOT_USE', -- Hash placeholder (não utilizável)
    'System',
    'System',
    NULL,
    NULL,
    FALSE,
    NULL,
    'Administrator',
    'Active',
    NULL, -- Admin não tem RiskProfile
    NULL, -- Admin não tem Subscription
    NULL, -- Admin não tem BillingPeriod
    NULL,
    NULL,
    CURRENT_TIMESTAMP,
    NULL
);

-- Configuração global do sistema (valores padrão do mercado brasileiro)
INSERT INTO SystemConfigs (
    BrokerCommissionRate,
    B3EmolumentRate,
    SettlementFeeRate,
    IssRate,
    IncomeTaxRate,
    DayTradeIncomeTaxRate,
    MaxOpenStrategiesPerUser,
    MaxStrategiesInTemplate,
    UpdatedAt,
    UpdatedBy
) VALUES (
    0.00000000, -- 0% - Maioria das corretoras tem corretagem zero
    0.00032500, -- 0.0325% - Taxa B3
    0.00027500, -- 0.0275% - Taxa de liquidação
    0.05000000, -- 5% - ISS sobre emolumentos
    0.15000000, -- 15% - IR sobre lucro swing-trade
    0.20000000, -- 20% - IR sobre lucro day-trade
    100,        -- Limite global: 100 estratégias abertas por usuário
    10,         -- Limite: 10 estratégias por template
    CURRENT_TIMESTAMP,
    '00000000-0000-0000-0000-000000000000' -- System User
) ON CONFLICT DO NOTHING;

-- =====================================================
-- SEED: Admin User (primeiro administrador)
-- =====================================================

-- Senha padrão: "Admin@123" (deve ser alterada no primeiro login)
-- BCrypt hash com cost=11
INSERT INTO Users (
    Id,
    Email,
    PasswordHash,
    FullName,
    DisplayName,
    PhoneCountryCode,
    PhoneNumber,
    IsPhoneVerified,
    PhoneVerifiedAt,
    Role,
    Status,
    RiskProfile,
    SubscriptionPlanId,
    BillingPeriod,
    PlanOverride,
    CustomFees,
    CreatedAt,
    LastLoginAt
) VALUES (
    '00000000-0000-0000-0000-000000000001', -- Admin User
    'admin@mytradergeo.com',
    '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- Admin@123
    'Administrator',
    'Admin',
    NULL,
    NULL,
    FALSE,
    NULL,
    'Administrator',
    'Active',
    NULL, -- Admin não tem RiskProfile
    NULL, -- Admin não tem Subscription
    NULL, -- Admin não tem BillingPeriod
    NULL,
    NULL,
    CURRENT_TIMESTAMP,
    NULL
);

-- =====================================================
-- SEED: Demo Trader Users (para testes)
-- =====================================================

-- Demo Trader 1: Plano Básico, Perfil Conservador
-- Senha: "Trader@123"
INSERT INTO Users (
    Id,
    Email,
    PasswordHash,
    FullName,
    DisplayName,
    PhoneCountryCode,
    PhoneNumber,
    IsPhoneVerified,
    PhoneVerifiedAt,
    Role,
    Status,
    RiskProfile,
    SubscriptionPlanId,
    BillingPeriod,
    PlanOverride,
    CustomFees,
    CreatedAt,
    LastLoginAt
) VALUES (
    '10000000-0000-0000-0000-000000000001',
    'trader.basico@demo.com',
    '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- Trader@123
    'Trader Básico Demo',
    'TraderBasico',
    '+55',
    '11987654321',
    TRUE,
    CURRENT_TIMESTAMP,
    'Trader',
    'Active',
    'Conservador',
    (SELECT Id FROM SubscriptionPlans WHERE Name = 'Básico'), -- Plano Básico
    1, -- Monthly
    NULL,
    NULL,
    CURRENT_TIMESTAMP,
    NULL
);

-- Demo Trader 2: Plano Pleno, Perfil Moderado
-- Senha: "Trader@123"
INSERT INTO Users (
    Id,
    Email,
    PasswordHash,
    FullName,
    DisplayName,
    PhoneCountryCode,
    PhoneNumber,
    IsPhoneVerified,
    PhoneVerifiedAt,
    Role,
    Status,
    RiskProfile,
    SubscriptionPlanId,
    BillingPeriod,
    PlanOverride,
    CustomFees,
    CreatedAt,
    LastLoginAt
) VALUES (
    '20000000-0000-0000-0000-000000000002',
    'trader.pleno@demo.com',
    '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- Trader@123
    'Trader Pleno Demo',
    'TraderPleno',
    '+55',
    '11987654322',
    TRUE,
    CURRENT_TIMESTAMP,
    'Trader',
    'Active',
    'Moderado',
    (SELECT Id FROM SubscriptionPlans WHERE Name = 'Pleno'), -- Plano Pleno
    12, -- Annual
    NULL,
    NULL,
    CURRENT_TIMESTAMP,
    NULL
);

-- Demo Trader 3: Plano Consultor, Perfil Agressivo
-- Senha: "Trader@123"
INSERT INTO Users (
    Id,
    Email,
    PasswordHash,
    FullName,
    DisplayName,
    PhoneCountryCode,
    PhoneNumber,
    IsPhoneVerified,
    PhoneVerifiedAt,
    Role,
    Status,
    RiskProfile,
    SubscriptionPlanId,
    BillingPeriod,
    PlanOverride,
    CustomFees,
    CreatedAt,
    LastLoginAt
) VALUES (
    '30000000-0000-0000-0000-000000000003',
    'trader.consultor@demo.com',
    '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- Trader@123
    'Trader Consultor Demo',
    'TraderConsultor',
    '+55',
    '11987654323',
    TRUE,
    CURRENT_TIMESTAMP,
    'Trader',
    'Active',
    'Agressivo',
    (SELECT Id FROM SubscriptionPlans WHERE Name = 'Consultor'), -- Plano Consultor
    12, -- Annual
    NULL,
    NULL,
    CURRENT_TIMESTAMP,
    NULL
);

-- Demo Trader 4: Plano Básico com Plan Override (Beta Tester)
-- Senha: "Trader@123"
INSERT INTO Users (
    Id,
    Email,
    PasswordHash,
    FullName,
    DisplayName,
    PhoneCountryCode,
    PhoneNumber,
    IsPhoneVerified,
    PhoneVerifiedAt,
    Role,
    Status,
    RiskProfile,
    SubscriptionPlanId,
    BillingPeriod,
    PlanOverride,
    CustomFees,
    CreatedAt,
    LastLoginAt
) VALUES (
    '40000000-0000-0000-0000-000000000004',
    'trader.beta@demo.com',
    '$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- Trader@123
    'Trader Beta Demo',
    'TraderBeta',
    '+55',
    '11987654324',
    TRUE,
    CURRENT_TIMESTAMP,
    'Trader',
    'Active',
    'Moderado',
    (SELECT Id FROM SubscriptionPlans WHERE Name = 'Básico'), -- Plano Básico
    1, -- Monthly
    '{
        "StrategyLimitOverride": 50,
        "FeaturesOverride": {
            "RealtimeData": true,
            "AdvancedAlerts": true,
            "ConsultingTools": false,
            "CommunityAccess": true
        },
        "ExpiresAt": "2025-12-31T23:59:59Z",
        "Reason": "Beta Tester",
        "GrantedBy": "00000000-0000-0000-0000-000000000001",
        "GrantedAt": "2025-10-26T00:00:00Z"
    }'::jsonb,
    NULL,
    CURRENT_TIMESTAMP,
    NULL
);

-- =====================================================
-- VERIFICATION QUERIES (para validação pós-seed)
-- =====================================================

-- Verificar planos criados
-- SELECT Name, PriceMonthlyAmount, StrategyLimit, FeatureRealtimeData FROM SubscriptionPlans ORDER BY PriceMonthlyAmount;

-- Verificar configuração do sistema
-- SELECT BrokerCommissionRate, IncomeTaxRate, MaxOpenStrategiesPerUser FROM SystemConfigs;

-- Verificar usuários criados
-- SELECT Email, Role, SubscriptionPlanId, RiskProfile FROM Users ORDER BY CreatedAt;

-- Verificar trader com override
-- SELECT DisplayName, PlanOverride FROM Users WHERE PlanOverride IS NOT NULL;
