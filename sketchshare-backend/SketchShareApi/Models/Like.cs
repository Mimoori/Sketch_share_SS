using System.ComponentModel.DataAnnotations;

namespace SketchShareApi.Models;

public class Like
{
    [Key]
    public int Id { get; set; }
    
    public int User_Id { get; set; }
    public int Post_Id { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    //public int Count { get; set; } = 0;

    public User User { get; set; } = null!;
    public Post Post { get; set; } = null!;
}