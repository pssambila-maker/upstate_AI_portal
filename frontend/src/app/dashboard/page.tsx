'use client';

import { useState, useEffect, useRef } from 'react';
import { useAuthState } from 'react-firebase-hooks/auth';
import { signOut } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { chat, getModels, getUsage, type Message, type Model, type UsageStats } from '@/lib/ai';
import AuthGuard from '@/components/AuthGuard';
import toast from 'react-hot-toast';
import ReactMarkdown from 'react-markdown';
import {
  Send,
  Loader2,
  LogOut,
  Settings,
  History,
  DollarSign,
  Zap,
  ChevronDown,
} from 'lucide-react';

export default function DashboardPage() {
  return (
    <AuthGuard>
      <Dashboard />
    </AuthGuard>
  );
}

function Dashboard() {
  const [user] = useAuthState(auth);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [models, setModels] = useState<Model[]>([]);
  const [selectedModel, setSelectedModel] = useState<string>('claude-3-5-sonnet-20241022');
  const [showModelSelector, setShowModelSelector] = useState(false);
  const [usage, setUsage] = useState<UsageStats | null>(null);
  const [showUsage, setShowUsage] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadModels();
    loadUsage();
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadModels = async () => {
    try {
      const modelList = await getModels();
      setModels(modelList);
    } catch (error) {
      console.error('Failed to load models:', error);
      toast.error('Failed to load models');
    }
  };

  const loadUsage = async () => {
    try {
      const stats = await getUsage();
      setUsage(stats);
    } catch (error) {
      console.error('Failed to load usage:', error);
    }
  };

  const handleSend = async () => {
    if (!input.trim() || loading) return;

    const userMessage: Message = {
      role: 'user',
      content: input.trim(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setLoading(true);

    try {
      const response = await chat({
        model: selectedModel,
        messages: [...messages, userMessage],
        maxTokens: 2000,
        temperature: 0.7,
      });

      const assistantMessage: Message = {
        role: 'assistant',
        content: response.content,
      };

      setMessages((prev) => [...prev, assistantMessage]);

      // Reload usage stats
      await loadUsage();
    } catch (error: any) {
      console.error('Chat error:', error);
      toast.error(error.message || 'Failed to send message');

      // Remove the user message on error
      setMessages((prev) => prev.slice(0, -1));
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const clearChat = () => {
    if (confirm('Clear all messages?')) {
      setMessages([]);
    }
  };

  const currentModel = models.find((m) => m.id === selectedModel);

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Upstate AI Portal</h1>
            <p className="text-sm text-gray-500">Multi-model AI Assistant</p>
          </div>

          <div className="flex items-center gap-4">
            {/* Usage Stats */}
            {usage && (
              <button
                onClick={() => setShowUsage(!showUsage)}
                className="flex items-center gap-2 px-3 py-2 text-sm bg-green-50 text-green-700 rounded-lg hover:bg-green-100"
              >
                <DollarSign className="w-4 h-4" />
                <span className="font-medium">
                  ${usage.current.totalCost.toFixed(4)}
                </span>
                <span className="text-green-600">
                  ({usage.current.requestCount}/100 requests)
                </span>
              </button>
            )}

            {/* User Menu */}
            <div className="flex items-center gap-3">
              <span className="text-sm text-gray-600">{user?.email}</span>
              <button
                onClick={() => signOut(auth)}
                className="p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg"
                title="Sign Out"
              >
                <LogOut className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Chat Area */}
        <div className="flex-1 flex flex-col">
          {/* Model Selector */}
          <div className="bg-white border-b border-gray-200 px-6 py-3">
            <div className="flex items-center justify-between">
              <div className="relative">
                <button
                  onClick={() => setShowModelSelector(!showModelSelector)}
                  className="flex items-center gap-2 px-4 py-2 bg-primary-50 text-primary-700 rounded-lg hover:bg-primary-100 transition-colors"
                >
                  <Zap className="w-4 h-4" />
                  <span className="font-medium">{currentModel?.name || 'Select Model'}</span>
                  <ChevronDown className="w-4 h-4" />
                </button>

                {showModelSelector && (
                  <div className="absolute top-full mt-2 w-80 bg-white rounded-lg shadow-xl border border-gray-200 z-10 max-h-96 overflow-y-auto">
                    {models.map((model) => (
                      <button
                        key={model.id}
                        onClick={() => {
                          setSelectedModel(model.id);
                          setShowModelSelector(false);
                        }}
                        className={`w-full text-left px-4 py-3 hover:bg-gray-50 border-b border-gray-100 ${
                          selectedModel === model.id ? 'bg-primary-50' : ''
                        }`}
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="font-medium text-gray-900">{model.name}</div>
                            <div className="text-xs text-gray-500 mt-0.5">{model.provider}</div>
                            <div className="text-xs text-gray-600 mt-1">{model.description}</div>
                          </div>
                          <div className="text-right ml-3">
                            <div className="text-xs text-gray-500">
                              ${model.inputCost}/{model.outputCost}
                            </div>
                            <div className="text-xs text-gray-400">per 1M tokens</div>
                          </div>
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </div>

              <button
                onClick={clearChat}
                className="px-4 py-2 text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg"
              >
                Clear Chat
              </button>
            </div>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto px-6 py-6">
            {messages.length === 0 ? (
              <div className="h-full flex items-center justify-center">
                <div className="text-center max-w-md">
                  <h2 className="text-2xl font-bold text-gray-900 mb-2">
                    Welcome to Upstate AI Portal
                  </h2>
                  <p className="text-gray-600 mb-6">
                    Start a conversation with any AI model. Choose from Claude, GPT, or Gemini.
                  </p>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div className="p-4 bg-blue-50 rounded-lg text-left">
                      <div className="font-medium text-blue-900 mb-1">Clinical Support</div>
                      <div className="text-blue-700 text-xs">
                        Differential diagnosis, treatment plans, documentation
                      </div>
                    </div>
                    <div className="p-4 bg-green-50 rounded-lg text-left">
                      <div className="font-medium text-green-900 mb-1">Medical Coding</div>
                      <div className="text-green-700 text-xs">
                        ICD-10, CPT codes, billing assistance
                      </div>
                    </div>
                    <div className="p-4 bg-purple-50 rounded-lg text-left">
                      <div className="font-medium text-purple-900 mb-1">Research</div>
                      <div className="text-purple-700 text-xs">
                        Literature review, evidence synthesis
                      </div>
                    </div>
                    <div className="p-4 bg-orange-50 rounded-lg text-left">
                      <div className="font-medium text-orange-900 mb-1">Administration</div>
                      <div className="text-orange-700 text-xs">
                        Policies, workflows, documentation
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-6 max-w-4xl mx-auto">
                {messages.map((message, index) => (
                  <div
                    key={index}
                    className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div
                      className={`max-w-[80%] rounded-lg px-4 py-3 ${
                        message.role === 'user'
                          ? 'bg-primary-600 text-white'
                          : 'bg-white border border-gray-200 text-gray-900'
                      }`}
                    >
                      {message.role === 'assistant' ? (
                        <ReactMarkdown className="markdown">{message.content}</ReactMarkdown>
                      ) : (
                        <p className="whitespace-pre-wrap">{message.content}</p>
                      )}
                    </div>
                  </div>
                ))}
                {loading && (
                  <div className="flex justify-start">
                    <div className="bg-white border border-gray-200 rounded-lg px-4 py-3">
                      <Loader2 className="w-5 h-5 animate-spin text-primary-600" />
                    </div>
                  </div>
                )}
                <div ref={messagesEndRef} />
              </div>
            )}
          </div>

          {/* Input Area */}
          <div className="bg-white border-t border-gray-200 px-6 py-4">
            <div className="max-w-4xl mx-auto">
              <div className="flex gap-3">
                <textarea
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Type your message... (Shift+Enter for new line)"
                  rows={3}
                  disabled={loading}
                  className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none disabled:opacity-50"
                />
                <button
                  onClick={handleSend}
                  disabled={loading || !input.trim()}
                  className="px-6 bg-primary-600 text-white rounded-lg hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center"
                >
                  {loading ? (
                    <Loader2 className="w-5 h-5 animate-spin" />
                  ) : (
                    <Send className="w-5 h-5" />
                  )}
                </button>
              </div>
              <p className="text-xs text-gray-500 mt-2">
                AI responses may contain errors. Always verify important information.
              </p>
            </div>
          </div>
        </div>

        {/* Usage Panel (if visible) */}
        {showUsage && usage && (
          <div className="w-80 bg-white border-l border-gray-200 p-6 overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text-gray-900">Usage Statistics</h3>
              <button
                onClick={() => setShowUsage(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                ×
              </button>
            </div>

            <div className="space-y-4">
              <div className="p-4 bg-blue-50 rounded-lg">
                <div className="text-sm text-blue-700 mb-1">Requests (Hourly)</div>
                <div className="text-2xl font-bold text-blue-900">
                  {usage.current.requestCount}/100
                </div>
              </div>

              <div className="p-4 bg-green-50 rounded-lg">
                <div className="text-sm text-green-700 mb-1">Total Cost</div>
                <div className="text-2xl font-bold text-green-900">
                  ${usage.current.totalCost.toFixed(4)}
                </div>
              </div>

              <div className="p-4 bg-purple-50 rounded-lg">
                <div className="text-sm text-purple-700 mb-1">Tokens Used</div>
                <div className="text-2xl font-bold text-purple-900">
                  {Math.round(usage.current.totalTokens / 1000)}K
                </div>
              </div>

              {usage.history.length > 0 && (
                <div className="mt-6">
                  <h4 className="text-sm font-medium text-gray-700 mb-3">Recent Activity</h4>
                  <div className="space-y-2">
                    {usage.history.slice(0, 10).map((item, index) => (
                      <div key={index} className="text-xs bg-gray-50 p-2 rounded">
                        <div className="font-medium text-gray-900">{item.model}</div>
                        <div className="text-gray-600 mt-1">
                          {item.inputTokens + item.outputTokens} tokens · ${item.cost.toFixed(4)}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
