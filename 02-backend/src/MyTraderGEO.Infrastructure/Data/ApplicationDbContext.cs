using Microsoft.EntityFrameworkCore;
using MyTraderGEO.Infrastructure.Data.Models;

namespace MyTraderGEO.Infrastructure.Data;

/// <summary>
/// EF Core Database Context for myTraderGEO
/// </summary>
public partial class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<User> Users { get; set; }
    public virtual DbSet<SubscriptionPlan> SubscriptionPlans { get; set; }
    public virtual DbSet<SystemConfig> SystemConfigs { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // SubscriptionPlan Configuration
        modelBuilder.Entity<SubscriptionPlan>(entity =>
        {
            entity.ToTable("subscriptionplans");

            entity.HasKey(e => e.Id);

            entity.Property(e => e.Id)
                .HasColumnName("id");

            entity.Property(e => e.Name)
                .IsRequired()
                .HasMaxLength(50)
                .HasColumnName("name");

            entity.Property(e => e.PriceMonthlyAmount)
                .HasPrecision(10, 2)
                .HasColumnName("pricemonthlyamount");

            entity.Property(e => e.PriceMonthlyCurrency)
                .IsRequired()
                .HasMaxLength(3)
                .HasDefaultValue("BRL")
                .HasColumnName("pricemonthlycurrency");

            entity.Property(e => e.PriceAnnualAmount)
                .HasPrecision(10, 2)
                .HasColumnName("priceannualamount");

            entity.Property(e => e.PriceAnnualCurrency)
                .IsRequired()
                .HasMaxLength(3)
                .HasDefaultValue("BRL")
                .HasColumnName("priceannualcurrency");

            entity.Property(e => e.AnnualDiscountPercent)
                .HasPrecision(5, 4)
                .HasColumnName("annualdiscountpercent");

            entity.Property(e => e.StrategyLimit)
                .HasColumnName("strategylimit");

            entity.Property(e => e.FeatureRealtimeData)
                .HasDefaultValue(false)
                .HasColumnName("featurerealtimedata");

            entity.Property(e => e.FeatureAdvancedAlerts)
                .HasDefaultValue(false)
                .HasColumnName("featureadvancedalerts");

            entity.Property(e => e.FeatureConsultingTools)
                .HasDefaultValue(false)
                .HasColumnName("featureconsultingtools");

            entity.Property(e => e.FeatureCommunityAccess)
                .HasDefaultValue(true)
                .HasColumnName("featurecommunityaccess");

            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("isactive");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("createdat");

            entity.Property(e => e.UpdatedAt)
                .HasColumnName("updatedat");

            entity.HasIndex(e => e.Name, "ux_subscriptionplans_name")
                .IsUnique();

            entity.HasIndex(e => e.IsActive, "ix_subscriptionplans_isactive");

            entity.HasIndex(e => e.CreatedAt, "ix_subscriptionplans_createdat");
        });

        // SystemConfig Configuration
        modelBuilder.Entity<SystemConfig>(entity =>
        {
            entity.ToTable("systemconfigs");

            entity.HasKey(e => e.Id);

            entity.Property(e => e.Id)
                .HasColumnName("id");

            entity.Property(e => e.BrokerCommissionRate)
                .HasPrecision(10, 8)
                .HasColumnName("brokercommissionrate");

            entity.Property(e => e.B3EmolumentRate)
                .HasPrecision(10, 8)
                .HasColumnName("b3emolumentrate");

            entity.Property(e => e.SettlementFeeRate)
                .HasPrecision(10, 8)
                .HasColumnName("settlementfeerate");

            entity.Property(e => e.IssRate)
                .HasPrecision(10, 8)
                .HasColumnName("issrate");

            entity.Property(e => e.IncomeTaxRate)
                .HasPrecision(10, 8)
                .HasColumnName("incometaxrate");

            entity.Property(e => e.DayTradeIncomeTaxRate)
                .HasPrecision(10, 8)
                .HasColumnName("daytradeincometaxrate");

            entity.Property(e => e.MaxOpenStrategiesPerUser)
                .HasColumnName("maxopenstrategiesperuser");

            entity.Property(e => e.MaxStrategiesInTemplate)
                .HasColumnName("maxstrategiesintemplate");

            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("updatedat");

            entity.Property(e => e.UpdatedBy)
                .HasColumnName("updatedby");

            entity.HasOne(d => d.UpdatedByUser)
                .WithMany(p => p.SystemConfigsUpdated)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("fk_systemconfigs_updatedby");
        });

        // User Configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users");

            entity.HasKey(e => e.Id);

            entity.Property(e => e.Id)
                .HasColumnName("id");

            entity.Property(e => e.Email)
                .IsRequired()
                .HasMaxLength(255)
                .HasColumnName("email");

            entity.Property(e => e.PasswordHash)
                .IsRequired()
                .HasMaxLength(255)
                .HasColumnName("passwordhash");

            entity.Property(e => e.FullName)
                .IsRequired()
                .HasMaxLength(255)
                .HasColumnName("fullname");

            entity.Property(e => e.DisplayName)
                .IsRequired()
                .HasMaxLength(30)
                .HasColumnName("displayname");

            entity.Property(e => e.PhoneCountryCode)
                .HasMaxLength(5)
                .HasColumnName("phonecountrycode");

            entity.Property(e => e.PhoneNumber)
                .HasMaxLength(15)
                .HasColumnName("phonenumber");

            entity.Property(e => e.IsPhoneVerified)
                .HasDefaultValue(false)
                .HasColumnName("isphoneverified");

            entity.Property(e => e.PhoneVerifiedAt)
                .HasColumnName("phoneverifiedat");

            entity.Property(e => e.Role)
                .IsRequired()
                .HasMaxLength(20)
                .HasColumnName("role");

            entity.Property(e => e.Status)
                .IsRequired()
                .HasMaxLength(20)
                .HasDefaultValue("Active")
                .HasColumnName("status");

            entity.Property(e => e.RiskProfile)
                .HasMaxLength(20)
                .HasColumnName("riskprofile");

            entity.Property(e => e.SubscriptionPlanId)
                .HasColumnName("subscriptionplanid");

            entity.Property(e => e.BillingPeriod)
                .HasColumnName("billingperiod");

            entity.Property(e => e.PlanOverride)
                .HasColumnType("jsonb")
                .HasColumnName("planoverride");

            entity.Property(e => e.CustomFees)
                .HasColumnType("jsonb")
                .HasColumnName("customfees");

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnName("createdat");

            entity.Property(e => e.LastLoginAt)
                .HasColumnName("lastloginat");

            entity.HasOne(d => d.SubscriptionPlan)
                .WithMany(p => p.Users)
                .HasForeignKey(d => d.SubscriptionPlanId)
                .HasConstraintName("fk_users_subscriptionplanid");

            entity.HasIndex(e => e.Email, "ux_users_email")
                .IsUnique();

            entity.HasIndex(e => e.Role, "ix_users_role");

            entity.HasIndex(e => e.Status, "ix_users_status");

            entity.HasIndex(e => e.SubscriptionPlanId, "ix_users_subscriptionplanid");

            entity.HasIndex(e => e.CreatedAt, "ix_users_createdat");

            entity.HasIndex(e => e.LastLoginAt, "ix_users_lastloginat");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
