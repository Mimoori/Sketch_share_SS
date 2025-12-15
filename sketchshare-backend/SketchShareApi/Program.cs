using Microsoft.EntityFrameworkCore;
using SketchShareApi.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql("Host=localhost;Port=5432;Database=sketchshare;Username=admin;Password=12345"));

builder.Services.AddControllers();

var app = builder.Build();

app.UseStaticFiles(); 
app.UseHttpsRedirection();
app.MapControllers();

app.Run();