using System.ComponentModel.DataAnnotations;

namespace SketchShareApi.Models;

public class User
{
    [Key]
    public int Id_User { get; set; }

    public string Name { get; set; } = string.Empty;
    public string Surname { get; set; } = string.Empty;
    public string Nickname { get; set; } = string.Empty;
    public DateTime Birthday { get; set; }
    public string Email { get; set; } = string.Empty;
    public int Role_Id { get; set; }
    public string Password { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public int Avatar { get; set; } 

    public Role Role { get; set; } = null!;
    public List<Post> Posts { get; set; } = new();
    public List<Like> Likes { get; set; } = new();
}