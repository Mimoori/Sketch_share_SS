// Controllers/PostsController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SketchShareApi.Data;
using SketchShareApi.Models;

[ApiController]
[Route("api/[controller]")]
public class PostsController : ControllerBase
{
    private readonly AppDbContext _db;

    public PostsController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<List<Post>>> Get() =>
        await _db.Posts.Include(p => p.User).Include(p => p.Image).ToListAsync();

    [HttpPost]
    public async Task<ActionResult> Post([FromBody] CreatePostDto dto)
    {
        var post = new Post
        {
            Title = dto.Title,
            Description = dto.Description,
            UserId = dto.UserId,
            ImageId = dto.ImageId,
            PostRoleId = dto.PostRoleId
        };
        _db.Posts.Add(post);
        await _db.SaveChangesAsync();
        return Ok();
    }
}

public record CreatePostDto(string Title, string Description, int UserId, int ImageId, int PostRoleId);