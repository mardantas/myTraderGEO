using System;

namespace MyTraderGEO.Infrastructure.Data.Models;

/// <summary>
/// EF Core entity for SystemConfig aggregate (Singleton)
/// Auto-generated placeholder - will be replaced by EF scaffold when database is ready
/// </summary>
public partial class SystemConfig
{
    public Guid Id { get; set; }

    // Taxas Operacionais
    public decimal BrokerCommissionRate { get; set; }
    public decimal B3EmolumentRate { get; set; }
    public decimal SettlementFeeRate { get; set; }
    public decimal IssRate { get; set; }

    // Impostos
    public decimal IncomeTaxRate { get; set; }
    public decimal DayTradeIncomeTaxRate { get; set; }

    // Limites Globais
    public int MaxOpenStrategiesPerUser { get; set; }
    public int MaxStrategiesInTemplate { get; set; }

    // Audit
    public DateTime UpdatedAt { get; set; }
    public Guid UpdatedBy { get; set; }

    // Navigation Properties
    public virtual User UpdatedByUser { get; set; } = null!;
}
