using Microsoft.EntityFrameworkCore;
using SketchShareApi.Models;

namespace SketchShareApi.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Post> Posts { get; set; }
        public DbSet<Like> Likes { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Настройка Post
            modelBuilder.Entity<Post>()
                .HasOne(p => p.User)
                .WithMany(u => u.Posts)
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Post>()
                .Property(p => p.CreatedAt)
                .HasDefaultValueSql("NOW()");

            // Настройка Like
            modelBuilder.Entity<Like>()
                .HasOne(l => l.Post)
                .WithMany(p => p.Likes)
                .HasForeignKey(l => l.Post_Id)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Like>()
                .HasOne(l => l.User)
                .WithMany(u => u.Likes)
                .HasForeignKey(l => l.User_Id)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Like>()
                .Property(l => l.CreatedAt)
                .HasDefaultValueSql("NOW()");

            // Создание индексов для производительности
            modelBuilder.Entity<Post>()
                .HasIndex(p => p.CreatedAt);

            modelBuilder.Entity<Post>()
                .HasIndex(p => p.LikeCount);

            modelBuilder.Entity<Post>()
                .HasIndex(p => p.UserId);

            modelBuilder.Entity<Like>()
                .HasIndex(l => l.Post_Id);

            modelBuilder.Entity<Like>()
                .HasIndex(l => l.User_Id);

            modelBuilder.Entity<Like>()
                .HasIndex(l => new { l.Post_Id, l.User_Id })
                .IsUnique(); // Уникальный лайк от пользователя на пост

            // Настройка User
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Name)
                .IsUnique();
        }
    }
}