// Controllers/AuthController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SketchShareApi.Data;
using SketchShareApi.Models;
using BCrypt.Net;


namespace SketchShareApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IWebHostEnvironment _env;

    public AuthController(AppDbContext db, IWebHostEnvironment env)
    {
        _db = db;
        _env = env;
    }

    [HttpPost("register")]
    public async Task<ActionResult> Register([FromBody] RegisterDto dto)
    {
        if (await _db.Users.AnyAsync(u => u.Email == dto.Email))
            return BadRequest("Email уже занят");

        var user = new User
        {
            Email = dto.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Name = dto.Name,
            Nickname = dto.Nickname,
            RoleId = 2 // обычный юзер
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Регистрация успешна", userId = user.Id });
    }

    [HttpPost("upload-avatar/{userId}")]
    public async Task<ActionResult<string>> UploadAvatar(int userId, IFormFile file)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        if (file == null || file.Length == 0) return BadRequest("Файл пустой");

        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "avatars");
        Directory.CreateDirectory(uploadsFolder);

        var fileName = $"{userId}_{Guid.NewGuid()}.jpg";
        var filePath = Path.Combine(uploadsFolder, fileName);

        await using var stream = new FileStream(filePath, FileMode.Create);
        await file.CopyToAsync(stream);

        var url = $"/avatars/{fileName}";
        user.AvatarUrl = url;
        await _db.SaveChangesAsync();

        return Ok(url);
    }

    [HttpGet("profile/{userId}")]
    public async Task<ActionResult<object>> GetProfile(int userId)
    {
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        return Ok(new
        {
            user.Name,
            user.Nickname,
            user.Email,
            user.AvatarUrl
        });
    }
}

public record RegisterDto(string Email, string Password, string Name, string Nickname);