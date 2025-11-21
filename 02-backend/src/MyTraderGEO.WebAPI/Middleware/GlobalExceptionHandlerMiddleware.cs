using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Text.Json;

namespace MyTraderGEO.WebAPI.Middleware;

/// <summary>
/// Global exception handler middleware implementing RFC 7807 Problem Details
/// </summary>
public class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private static async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var problemDetails = exception switch
        {
            ValidationException validationException => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/validation-error",
                Title = "Erro de Validação",
                Status = (int)HttpStatusCode.BadRequest,
                Detail = "Ocorreram um ou mais erros de validação.",
                Extensions =
                {
                    ["errors"] = validationException.Errors
                        .GroupBy(e => e.PropertyName)
                        .ToDictionary(
                            g => g.Key,
                            g => g.Select(e => e.ErrorMessage).ToArray())
                }
            },
            InvalidOperationException => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/business-rule-violation",
                Title = "Violação de Regra de Negócio",
                Status = (int)HttpStatusCode.BadRequest,
                Detail = exception.Message,
            },
            UnauthorizedAccessException => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/unauthorized",
                Title = "Não Autorizado",
                Status = (int)HttpStatusCode.Unauthorized,
                Detail = exception.Message,
            },
            ArgumentException => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/invalid-argument",
                Title = "Argumento Inválido",
                Status = (int)HttpStatusCode.BadRequest,
                Detail = exception.Message,
            },
            _ => new ProblemDetails
            {
                Type = "https://api.mytrader.com/errors/internal-server-error",
                Title = "Erro Interno do Servidor",
                Status = (int)HttpStatusCode.InternalServerError,
                Detail = "Ocorreu um erro inesperado. Por favor, tente novamente mais tarde.",
            }
        };

        // Add traceId for debugging (if not already added by validation exception)
        if (!problemDetails.Extensions.ContainsKey("traceId"))
        {
            problemDetails.Extensions["traceId"] = context.TraceIdentifier;
        }

        context.Response.ContentType = "application/problem+json";
        context.Response.StatusCode = problemDetails.Status ?? 500;

        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        await context.Response.WriteAsync(JsonSerializer.Serialize(problemDetails, options));
    }
}
