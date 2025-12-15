using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SketchShareApi.Models;

public class Image
{
    [Key]
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public byte[] ImageData { get; set; } = new byte[0];

    public List<Post> Posts { get; set; } = new List<Post>();
}