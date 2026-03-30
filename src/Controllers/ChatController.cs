using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ILogger<ChatController> _logger;
        private readonly ChatService _chatService;

        public ChatController(ILogger<ChatController> logger, ChatService chatService)
        {
            _logger = logger;
            _chatService = chatService;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Send([FromBody] ChatRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Message))
            {
                return BadRequest(new { error = "Message cannot be empty." });
            }

            _logger.LogInformation("Sending message to Phi-4 endpoint");

            try
            {
                var reply = await _chatService.SendMessageAsync(request.Message);
                return Ok(new { reply });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error communicating with Phi-4 endpoint");
                return StatusCode(500, new { error = "Unable to process your request. Please try again later." });
            }
        }

        public record ChatRequest(string Message);
    }
}
