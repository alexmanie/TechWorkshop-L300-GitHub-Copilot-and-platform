using Azure;
using Azure.AI.Inference;
using Azure.Identity;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly ChatCompletionsClient _client;
        private readonly string _modelDeployment;

        public ChatService(IConfiguration configuration)
        {
            var endpoint = configuration["AzureAI:Endpoint"]
                ?? throw new InvalidOperationException("AzureAI:Endpoint configuration is missing.");
            _modelDeployment = configuration["AzureAI:ModelDeployment"] ?? "Phi-4";

            _client = new ChatCompletionsClient(
                new Uri(endpoint),
                new DefaultAzureCredential());
        }

        public async Task<string> SendMessageAsync(string userMessage)
        {
            var requestOptions = new ChatCompletionsOptions
            {
                Model = _modelDeployment,
                Messages =
                {
                    new ChatRequestUserMessage(userMessage)
                }
            };

            var response = await _client.CompleteAsync(requestOptions);
            return response.Value.Content;
        }
    }
}
