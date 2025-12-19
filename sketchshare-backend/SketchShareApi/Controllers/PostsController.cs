using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SketchShareApi.Data;
using SketchShareApi.DTOs;
using SketchShareApi.Models;
using System.Drawing;

namespace SketchShareApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PostsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ILogger<PostsController> _logger;

    public PostsController(AppDbContext context, ILogger<PostsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: api/posts
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<PostResponseDto>>> GetPosts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? sortBy = "newest")
    {
        try
        {
            IQueryable<Post> query = _context.Posts
                .Where(p => !p.IsDeleted)
                .Include(p => p.User)
                .Include(p => p.Likes);

            query = sortBy?.ToLower() switch
            {
                "popular" => query.OrderByDescending(p => p.LikeCount),
                "views" => query.OrderByDescending(p => p.ViewCount),
                "oldest" => query.OrderBy(p => p.CreatedAt),
                _ => query.OrderByDescending(p => p.CreatedAt)
            };

            var totalCount = await query.CountAsync();
            var posts = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var currentUserId = GetCurrentUserId();
            var response = posts.Select(p => MapToDto(p, currentUserId)).ToList();

            Response.Headers.Append("X-Total-Count", totalCount.ToString());
            Response.Headers.Append("X-Total-Pages", Math.Ceiling(totalCount / (double)pageSize).ToString());

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting posts");
            return StatusCode(500, "Internal server error");
        }
    }

    // GET: api/posts/5
    [HttpGet("{id}")]
    [AllowAnonymous]
    public async Task<ActionResult<PostResponseDto>> GetPost(int id)
    {
        try
        {
            var post = await _context.Posts
                .Include(p => p.User)
                .Include(p => p.Likes)
                .FirstOrDefaultAsync(p => p.Id == id && !p.IsDeleted);

            if (post == null)
                return NotFound();

            post.ViewCount++;
            await _context.SaveChangesAsync();

            var currentUserId = GetCurrentUserId();
            return Ok(MapToDto(post, currentUserId));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting post {id}");
            return StatusCode(500, "Internal server error");
        }
    }

    // GET: api/posts/5/image
    [HttpGet("{id}/image")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPostImage(int id)
    {
        try
        {
            var post = await _context.Posts.FindAsync(id);
            if (post == null || post.IsDeleted || post.ImageData == null || post.ImageData.Length == 0)
                return NotFound();

            return File(post.ImageData, post.ImageContentType);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error getting image for post {id}");
            return StatusCode(500, "Internal server error");
        }
    }

    // POST: api/posts
    [Authorize]
    [HttpPost]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<PostResponseDto>> CreatePost([FromForm] PostCreateDto postDto)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                return Unauthorized("User not found");

            // Валидация файла
            if (postDto.ImageFile == null || postDto.ImageFile.Length == 0)
                return BadRequest("Image file is required");

            if (postDto.ImageFile.Length > 10 * 1024 * 1024) // 10MB
                return BadRequest("File size exceeds 10MB limit");

            var allowedExtensions = new[] { ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp" };
            var fileExtension = Path.GetExtension(postDto.ImageFile.FileName).ToLower();
            
            if (!allowedExtensions.Contains(fileExtension))
                return BadRequest($"Invalid file format. Allowed: {string.Join(", ", allowedExtensions)}");

            // Читаем файл в массив байтов
            byte[] imageData;
            using (var memoryStream = new MemoryStream())
            {
                await postDto.ImageFile.CopyToAsync(memoryStream);
                imageData = memoryStream.ToArray();
            }

            // Определяем ContentType
            var contentType = GetContentType(fileExtension);

            // Создаем пост
            var post = new Post
            {
                Title = postDto.Title.Trim(),
                Description = postDto.Description?.Trim() ?? string.Empty,
                UserId = userId,
                ImageData = imageData,
                ImageContentType = contentType,
                ImageFileName = postDto.ImageFile.FileName,
                CanvasWidth = postDto.CanvasWidth,
                CanvasHeight = postDto.CanvasHeight,
                FileSize = postDto.ImageFile.Length,
                StrokeCount = postDto.StrokeCount,
                CreatedAt = DateTime.UtcNow
            };

            _context.Posts.Add(post);
            await _context.SaveChangesAsync();

            var response = MapToDto(post, userId);
            return CreatedAtAction(nameof(GetPost), new { id = post.Id }, response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating post");
            return StatusCode(500, "Internal server error");
        }
    }

    // PUT: api/posts/5/like
    [Authorize]
    [HttpPut("{id}/like")]
    public async Task<ActionResult> ToggleLike(int id)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == 0)
                return Unauthorized();

            var post = await _context.Posts.FindAsync(id);
            if (post == null || post.IsDeleted)
                return NotFound();

            var existingLike = await _context.Likes
                .FirstOrDefaultAsync(l => l.Post_Id == id && l.User_Id == userId);

            if (existingLike != null)
            {
                _context.Likes.Remove(existingLike);
                post.LikeCount = Math.Max(0, post.LikeCount - 1);
            }
            else
            {
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
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error toggling like for post {id}");
            return StatusCode(500, "Internal server error");
        }
    }

    // DELETE: api/posts/5
    [Authorize]
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeletePost(int id, [FromBody] DeletePostDto deleteDto)
    {
        try
        {
            var userId = GetCurrentUserId();
            var post = await _context.Posts.FindAsync(id);

            if (post == null)
                return NotFound();

            var isAdmin = User.IsInRole("Admin");
            if (post.UserId != userId && !isAdmin)
                return Forbid();

            if (isAdmin)
            {
                post.IsDeleted = true;
                post.DeleteReason = deleteDto.Reason?.Trim();
                post.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                var likes = await _context.Likes.Where(l => l.Post_Id == id).ToListAsync();
                _context.Likes.RemoveRange(likes);
                _context.Posts.Remove(post);
            }

            await _context.SaveChangesAsync();
            return NoContent();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error deleting post {id}");
            return StatusCode(500, "Internal server error");
        }
    }

    // Вспомогательные методы
    private int GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst("userId")?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return 0;
        return userId;
    }

    private string GetContentType(string fileExtension)
    {
        return fileExtension switch
        {
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".gif" => "image/gif",
            ".webp" => "image/webp",
            ".bmp" => "image/bmp",
            ".svg" => "image/svg+xml",
            _ => "application/octet-stream"
        };
    }

    private PostResponseDto MapToDto(Post post, int currentUserId)
    {
        return new PostResponseDto
        {
            Id = post.Id,
            Title = post.Title,
            Description = post.Description,
            ImageUrl = $"/api/posts/{post.Id}/image",
            CanvasWidth = post.CanvasWidth,
            CanvasHeight = post.CanvasHeight,
            FileSize = post.FileSize,
            StrokeCount = post.StrokeCount,
            LikeCount = post.LikeCount,
            ViewCount = post.ViewCount,
            CreatedAt = post.CreatedAt,
            ContentType = post.ImageContentType,
            User = new UserResponseDto
            {
                Id = post.User.Id_User,
                Name = post.User.Name,
                Surname = post.User.Surname,
                Nickname = post.User.Nickname,
                Avatar = post.User.Avatar.ToString()
            },
            IsLiked = currentUserId > 0 && post.Likes.Any(l => l.User_Id == currentUserId)
        };
    }
}