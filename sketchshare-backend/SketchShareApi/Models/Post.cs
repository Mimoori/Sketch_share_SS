namespace SketchShareApi.Models;

public class Post
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public int ImageId { get; set; }
    public Image Image { get; set; } = null!;

    public int PostRoleId { get; set; }
    public Role PostRole { get; set; } = null!;

    public List<Like> Likes { get; set; } = new();
}