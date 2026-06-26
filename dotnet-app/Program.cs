var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Hello from Blue/Green deployment! v1.0");
app.MapGet("/health", () => Results.Ok(new { status = "healthy", version = "1.0" }));

app.Run("http://0.0.0.0:5000");
