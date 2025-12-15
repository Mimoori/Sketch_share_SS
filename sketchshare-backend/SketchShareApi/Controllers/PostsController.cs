// Controllers/PostsController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SketchShareApi.Data;
using SketchShareApi.Models;
using Microsoft.AspNetCore.Authorization;

[ApiController]
[Route("api/[controller]")]
public class PostsController : ControllerBase
{
    private readonly AppDbContext _context;

    public PostsController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/posts
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Post>>> GetPosts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? sortBy = "newest")
    {
        IQueryable<Post> query = _context.Posts
            .Where(p => !p.IsDeleted)
            .Include(p => p.User)
            .Include(p => p.Likes);

        // Сортировка
        query = sortBy switch
        {
            "popular" => query.OrderByDescending(p => p.LikeCount),
            "views" => query.OrderByDescending(p => p.ViewCount),
            _ => query.OrderByDescending(p => p.CreatedAt) // newest
        };

        var totalCount = await query.CountAsync();
        var posts = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        Response.Headers.Append("X-Total-Count", totalCount.ToString());
        Response.Headers.Append("X-Total-Pages", Math.Ceiling(totalCount / (double)pageSize).ToString());

        return posts;
    }

    // GET: api/posts/5
    [HttpGet("{id}")]
    public async Task<ActionResult<Post>> GetPost(int id)
    {
        var post = await _context.Posts
            .Include(p => p.User)
            .Include(p => p.Likes)
            .ThenInclude(c => c.User)
            .FirstOrDefaultAsync(p => p.Id == id && !p.IsDeleted);

        if (post == null)
            return NotFound();

        // Увеличиваем счетчик просмотров
        post.ViewCount++;
        await _context.SaveChangesAsync();

        return post;
    }

    // POST: api/posts
    [Authorize]
    [HttpPost]
    public async Task<ActionResult<Post>> CreatePost(PostCreateDto postDto)
    {
        // Проверяем userId из токена
        var userIdClaim = User.FindFirst("userId")?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();

        var post = new Post
        {
            Title = postDto.Title,
            Description = postDto.Description,
            UserId = userId,
            FirebaseImageUrl = postDto.FirebaseImageUrl,
            CanvasWidth = postDto.CanvasWidth,
            CanvasHeight = postDto.CanvasHeight,
            StrokeCount = postDto.StrokeCount,
            CreatedAt = DateTime.UtcNow
        };

        _context.Posts.Add(post);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetPost), new { id = post.Id }, post);
    }

    // PUT: api/posts/5/like
    [Authorize]
    [HttpPut("{id}/like")]
    public async Task<ActionResult> ToggleLike(int id)
    {
        var userIdClaim = User.FindFirst("userId")?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();

        var post = await _context.Posts.FindAsync(id);
        if (post == null || post.IsDeleted)
            return NotFound();

        var existingLike = await _context.Likes
            .FirstOrDefaultAsync(l => l.Post_Id == id && l.User_Id == userId);

        if (existingLike != null)
        {
            // Удаляем лайк
            _context.Likes.Remove(existingLike);
            post.LikeCount--;
        }
        else
        {
            // Добавляем лайк
            var like = new Like
            {
                Post_Id = id,
                User_Id = userId,
                CreatedAt = DateTime.UtcNow
            };
            _context.Likes.Add(like);
            post.LikeCount++;
        }

        await _context.SaveChangesAsync();
        return Ok(new { likeCount = post.LikeCount });
    }

    // DELETE: api/posts/5
    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeletePost(int id, [FromBody] DeletePostDto deleteDto)
    {
        var userIdClaim = User.FindFirst("userId")?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();

        var post = await _context.Posts.FindAsync(id);
        if (post == null)
            return NotFound();

        // Проверяем права (только автор или админ)
        var isAdmin = User.IsInRole("Admin");
        if (post.UserId != userId && !isAdmin)
            return Forbid();

        if (isAdmin)
        {
            // Админ скрывает пост
            post.IsDeleted = true;
            post.DeleteReason = deleteDto.Reason;
        }
        else
        {
            // Автор полностью удаляет
            _context.Posts.Remove(post);
        }

        await _context.SaveChangesAsync();
        return NoContent();
    }
}

// DTOs
public class PostCreateDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string FirebaseImageUrl { get; set; } = string.Empty;
    public int CanvasWidth { get; set; }
    public int CanvasHeight { get; set; }
    public int StrokeCount { get; set; }
}

public class DeletePostDto
{
    public string Reason { get; set; } = string.Empty;
}