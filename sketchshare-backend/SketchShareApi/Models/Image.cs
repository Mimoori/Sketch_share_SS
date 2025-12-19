using System.ComponentModel.DataAnnotations;

namespace SketchShareApi.Models;

public class Image
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public byte[] Data { get; set; } = Array.Empty<byte>();
    
    [Required]
    [MaxLength(100)]
    public string ContentType { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(255)]
    public string FileName { get; set; } = string.Empty;
    
    //public int Width { get; set; }
    //public int Height { get; set; }
    public long Size { get; set; }
    
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    
    // Ссылка на пост (если нужно отдельное хранение)
    public int? PostId { get; set; }
    public Post? Post { get; set; }
}