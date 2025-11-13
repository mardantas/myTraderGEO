using System;

namespace MyTraderGEO.Domain.UserManagement.ValueObjects;

/// <summary>
/// Value Object: Plan Features
/// Defines which features are included in a subscription plan
/// </summary>
public sealed class PlanFeatures : IEquatable<PlanFeatures>
{
    public bool RealtimeData { get; }
    public bool AdvancedAlerts { get; }
    public bool ConsultingTools { get; }
    public bool CommunityAccess { get; }

    private PlanFeatures(
        bool realtimeData,
        bool advancedAlerts,
        bool consultingTools,
        bool communityAccess)
    {
        RealtimeData = realtimeData;
        AdvancedAlerts = advancedAlerts;
        ConsultingTools = consultingTools;
        CommunityAccess = communityAccess;
    }

    public static PlanFeatures Create(
        bool realtimeData = false,
        bool advancedAlerts = false,
        bool consultingTools = false,
        bool communityAccess = true)
    {
        return new PlanFeatures(
            realtimeData,
            advancedAlerts,
            consultingTools,
            communityAccess);
    }

    /// <summary>
    /// Básico plan features (free tier)
    /// </summary>
    public static PlanFeatures BasicPlan() => new(
        realtimeData: false,
        advancedAlerts: false,
        consultingTools: false,
        communityAccess: true);

    /// <summary>
    /// Pleno plan features (paid tier 1)
    /// </summary>
    public static PlanFeatures PlenoPlan() => new(
        realtimeData: true,
        advancedAlerts: true,
        consultingTools: false,
        communityAccess: true);

    /// <summary>
    /// Consultor plan features (paid tier 2)
    /// </summary>
    public static PlanFeatures ConsultorPlan() => new(
        realtimeData: true,
        advancedAlerts: true,
        consultingTools: true,
        communityAccess: true);

    public bool Equals(PlanFeatures? other)
    {
        if (other is null) return false;
        return RealtimeData == other.RealtimeData
               && AdvancedAlerts == other.AdvancedAlerts
               && ConsultingTools == other.ConsultingTools
               && CommunityAccess == other.CommunityAccess;
    }

    public override bool Equals(object? obj) => obj is PlanFeatures other && Equals(other);

    public override int GetHashCode() => HashCode.Combine(
        RealtimeData,
        AdvancedAlerts,
        ConsultingTools,
        CommunityAccess);

    public override string ToString()
    {
        var features = new System.Collections.Generic.List<string>();
        if (RealtimeData) features.Add("Realtime Data");
        if (AdvancedAlerts) features.Add("Advanced Alerts");
        if (ConsultingTools) features.Add("Consulting Tools");
        if (CommunityAccess) features.Add("Community Access");

        return string.Join(", ", features);
    }

    public static bool operator ==(PlanFeatures? left, PlanFeatures? right) =>
        left is null ? right is null : left.Equals(right);

    public static bool operator !=(PlanFeatures? left, PlanFeatures? right) => !(left == right);
}
