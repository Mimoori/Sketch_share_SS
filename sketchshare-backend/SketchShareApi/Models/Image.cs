namespace SketchShareApi.Models;

public class Image
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public byte[] ImageData { get; set; } = Array.Empty<byte>();

    public List<Post> Posts { get; set; } = new();
}