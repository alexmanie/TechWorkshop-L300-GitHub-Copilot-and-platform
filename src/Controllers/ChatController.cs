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
        public async Task<IActionResult> Send(string message)
        {
            if (string.IsNullOrWhiteSpace(message))
            {
                return BadRequest("Message cannot be empty.");
            }

            _logger.LogInformation("Chat message received");
            var response = await _chatService.GetChatResponseAsync(message);
            return Content(response);
        }
    }
}
