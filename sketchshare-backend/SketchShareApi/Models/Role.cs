using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SketchShareApi.Models;

public class Role
{
    [Key]
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    public List<User> Users { get; set; } = new List<User>();
}