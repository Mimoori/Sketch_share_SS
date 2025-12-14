// Models/Sketch.cs
namespace SketchShareApi.Models;

public class Sketch
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public List<Like> Likes { get; set; } = new();
    public bool IsDeleted { get; set; } = false;
public string? DeleteReason { get; set; }
}