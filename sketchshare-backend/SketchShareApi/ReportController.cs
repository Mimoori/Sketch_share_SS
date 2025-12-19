// ReportController.cs
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReportsController : ControllerBase
{
    private readonly AppDbContext _context;
    
    [HttpPost]
    public async Task<ActionResult> CreateReport([FromBody] ReportCreateDto reportDto)
    {
        var userId = GetCurrentUserId();
        var report = new Report
        {
            PostId = reportDto.PostId,
            UserId = userId,
            Reason = reportDto.Reason,
            Status = "Pending",
            CreatedAt = DateTime.UtcNow
        };
        
        _context.Reports.Add(report);
        await _context.SaveChangesAsync();
        
        return Ok();
    }
    
    // GET: api/reports (только для админов)
    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> GetReports([FromQuery] string? status)
    {
        var query = _context.Reports
            .Include(r => r.Post)
            .Include(r => r.User);
            
        if (!string.IsNullOrEmpty(status))
            query = query.Where(r => r.Status == status);
            
        var reports = await query.ToListAsync();
        return Ok(reports);
    }
}

// Report.cs модель
public class Report
{
    public int Id { get; set; }
    public int PostId { get; set; }
    public int UserId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending"; // Pending, Reviewed, Resolved
    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public string? AdminNotes { get; set; }
    
    public Post Post { get; set; } = null!;
    public User User { get; set; } = null!;
}