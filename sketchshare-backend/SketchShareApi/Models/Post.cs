using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SketchShareApi.Models;

public class Post
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [MaxLength(1000)]
    public string Description { get; set; } = string.Empty;
    
    [Required]
    public int UserId { get; set; }
    
    // Изображение хранится в БД как byte array
    [Required]
    public byte[] ImageData { get; set; } = Array.Empty<byte>();
    
    public string ImageContentType { get; set; } = string.Empty; // "image/png", "image/jpeg"
    public string ImageFileName { get; set; } = string.Empty;
    
    // Миниатюра для превью
    public byte[]? ThumbnailData { get; set; }
    
    // Метаданные изображения
    public int CanvasWidth { get; set; }
    public int CanvasHeight { get; set; }
    public int ImageWidth { get; set; }
    public int ImageHeight { get; set; }
    public long FileSize { get; set; } // в байтах
    
    public int StrokeCount { get; set; } = 0;
    public int LikeCount { get; set; } = 0;
    public int ViewCount { get; set; } = 0;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public bool IsDeleted { get; set; } = false;
    public string? DeleteReason { get; set; }
    
    // Навигационные свойства
    [ForeignKey("UserId")]
    public User User { get; set; } = null!;
    
    public List<Like> Likes { get; set; } = new List<Like>();
    
    // Вычисляемые свойства
    [NotMapped]
    public double AspectRatio => CanvasHeight > 0 ? (double)CanvasWidth / CanvasHeight : 1.0;
    
    [NotMapped]
    public string Orientation => CanvasWidth > CanvasHeight ? "landscape" 
        : CanvasWidth < CanvasHeight ? "portrait" : "square";
}