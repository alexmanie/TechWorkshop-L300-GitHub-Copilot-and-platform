using Azure;
using Azure.AI.Inference;
using Azure.Identity;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly ChatCompletionsClient _client;
        private readonly string _deploymentName;
        private readonly ILogger<ChatService> _logger;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _logger = logger;
            var endpoint = configuration["AzureAI:Endpoint"]
                ?? throw new InvalidOperationException("AzureAI:Endpoint configuration is required.");
            _deploymentName = configuration["AzureAI:DeploymentName"] ?? "Phi-4";

            _client = new ChatCompletionsClient(
                new Uri(endpoint),
                new DefaultAzureCredential());
        }

        public async Task<string> GetChatResponseAsync(string userMessage)
        {
            _logger.LogInformation("Sending message to {Deployment}", _deploymentName);

            var requestOptions = new ChatCompletionsOptions
            {
                Model = _deploymentName,
                Messages =
                {
                    new ChatRequestUserMessage(userMessage)
                }
            };

            Response<ChatCompletions> response = await _client.CompleteAsync(requestOptions);
            var reply = response.Value.Content;
            _logger.LogInformation("Received response from {Deployment}", _deploymentName);
            return reply;
        }
    }
}
