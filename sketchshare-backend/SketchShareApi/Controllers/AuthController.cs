using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SketchShareApi.Data;
using SketchShareApi.Models;
using System.Security.Cryptography;
using System.Text;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;

    public AuthController(AppDbContext context)
    {
        _context = context;
    }

    [HttpPost("register")]
    public async Task<ActionResult<User>> Register(User request)
    {
        var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (existingUser != null) return BadRequest("Email already exists");

        string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.PasswordHash);

        var user = new User
        {
            Name = request.Name,
            Surname = request.Surname,
            Nickname = request.Nickname,
            Birthday = request.Birthday,
            Email = request.Email,
            Role_Id = request.Role_Id,
            PasswordHash = passwordHash, // Используем Hash
            Avatar = request.Avatar,
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok(user);
    }

    [HttpPost("login")]
    public async Task<ActionResult<User>> Login(User request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        if (user == null) return BadRequest("User not found");

        if (!BCrypt.Net.BCrypt.Verify(request.PasswordHash, user.PasswordHash)) {
            return BadRequest("Wrong password");
        }

        // Здесь можно добавить JWT или сессию, но для простоты возвращаем пользователя
        return Ok(user);
    }

    [HttpPost("update-avatar")]
    public async Task<ActionResult<string>> UpdateAvatar(int userId, int avatar)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        user.Avatar = avatar;
        await _context.SaveChangesAsync();

        return Ok(user.Avatar);
    }
}