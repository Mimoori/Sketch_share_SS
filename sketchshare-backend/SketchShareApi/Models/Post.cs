// Models/Post.cs
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SketchShareApi.Models;

public class Post
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public string Title { get; set; } = string.Empty;
    
    public string Description { get; set; } = string.Empty;
    
    [Required]
    public int UserId { get; set; }
    
    [Required]
    public string FirebaseImageUrl { get; set; } = string.Empty; // URL картинки в Firebase Storage
    
    public int LikeCount { get; set; } = 0;
    public int ViewCount { get; set; } = 0;
    
    [Required]
    public int CanvasWidth { get; set; }
    
    [Required]
    public int CanvasHeight { get; set; }
    
    public int StrokeCount { get; set; } = 0;
    
    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; } = false;
    public string? DeleteReason { get; set; }
    
    // Навигационные свойства
    [ForeignKey("UserId")]
    public User User { get; set; } = null!;
    
    public List<Like> Likes { get; set; } = new List<Like>();
}