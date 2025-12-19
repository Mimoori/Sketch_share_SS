using System.ComponentModel.DataAnnotations;

namespace SketchShareApi.DTOs;

public class PostCreateDto
{
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [MaxLength(1000)]
    public string Description { get; set; } = string.Empty;
    
    [Required]
    [Range(100, 5000)]
    public int CanvasWidth { get; set; }
    
    [Required]
    [Range(100, 5000)]
    public int CanvasHeight { get; set; }
    
    [Range(0, 10000)]
    public int StrokeCount { get; set; } = 0;
    
    [Required]
    public IFormFile ImageFile { get; set; } = null!;
}

public class PostResponseDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty; // URL для получения картинки
    public string? ThumbnailUrl { get; set; } // URL для миниатюры
    public int CanvasWidth { get; set; }
    public int CanvasHeight { get; set; }
    public int ImageWidth { get; set; }
    public int ImageHeight { get; set; }
    public long FileSize { get; set; }
    public int StrokeCount { get; set; }
    public int LikeCount { get; set; }
    public int ViewCount { get; set; }
    public DateTime CreatedAt { get; set; }
    public UserResponseDto User { get; set; } = null!;
    public bool IsLiked { get; set; }
    public string ContentType { get; set; } = string.Empty;
}

public class PostUpdateDto
{
    [MaxLength(200)]
    public string? Title { get; set; }
    
    [MaxLength(1000)]
    public string? Description { get; set; }
}

public class DeletePostDto
{
    [Required]
    public string Reason { get; set; } = string.Empty;
}