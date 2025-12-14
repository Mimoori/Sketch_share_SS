using Microsoft.EntityFrameworkCore;
using SketchShareApi.Models;

namespace SketchShareApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<Image> Images => Set<Image>();
    public DbSet<Like> Likes => Set<Like>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    // Для Like — составной ключ
    modelBuilder.Entity<Like>()
        .HasKey(l => new { l.UserId, l.PostId });

    // Или если оставил Id — тогда просто:
    modelBuilder.Entity<Like>().HasKey(l => l.Id);
}
}