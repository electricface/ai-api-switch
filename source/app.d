import std.stdio;
import std.file;
import std.path;
import std.json;
import std.algorithm;
import std.string;
import std.conv;

/// Configuration struct for storing Claude API settings
struct Config {
    /// Base URL for the Claude API endpoint
    string baseUrl;
    /// Authentication token for the Claude API
    string authToken;
}

void main(string[] args)
{
    if (args.length < 2) {
        writeln("Usage: claude-switch <profile>");
        writeln("Available profiles: ikun, yes");
        return;
    }

    string profile = args[1];
    string homeDir = Environment.get("HOME");
    
    try {
        // 读取配置文件
        string configPath = buildPath(homeDir, ".config", "ai-switch.json");
        
        if (!exists(configPath)) {
            // 创建默认配置文件
            createDefaultConfig(configPath);
        }
        
        Config config = loadConfig(configPath, profile);
        
        // 更新 Claude settings.json
        string claudeSettingsPath = buildPath(homeDir, ".claude", "settings.json");
        updateClaudeSettings(claudeSettingsPath, config);
        
        writeln("✓ Switched to profile: ", profile);
        writeln("\nCurrent settings.json:");
        displayClaudeSettings(claudeSettingsPath);
        
    } catch (Exception e) {
        writeln("Error: ", e.msg);
        writeln("\nStacktrace:");
        writeln(e.toString());
    }
}

/// Creates a default configuration file with sample profiles
void createDefaultConfig(string configPath) {
    JSONValue config = parseJSON(q{
        {
            "profiles": {
                "ikun": {
                    "baseUrl": "https://api.ikuncode.cc",
                    "authToken": "your-ikun-token-here"
                },
                "yes": {
                    "baseUrl": "https://co.yes.vg",
                    "authToken": "your-yes-token-here"
                }
            }
        }
    });
    
    mkdirRecurse(dirName(configPath));
    std.file.write(configPath, config.toPrettyString(JSONOptions.doNotEscapeSlashes));
    writeln("Created default config at: ", configPath);
    writeln("Please edit the config file to add your auth tokens.");
}

/// Loads configuration for a specific profile from the config file
Config loadConfig(string configPath, string profile) {
    string content = to!string(std.file.read(configPath));
    JSONValue json = parseJSON(content);
    
    if (profile !in json["profiles"].object) {
        throw new Exception("Profile '" ~ profile ~ "' not found in config");
    }
    
    JSONValue profileData = json["profiles"][profile];
    Config config;
    config.baseUrl = profileData["baseUrl"].str;
    config.authToken = profileData["authToken"].str;
    
    return config;
}

/// Updates Claude settings.json with the configuration from the selected profile
void updateClaudeSettings(string settingsPath, Config config) {
    JSONValue settings;
    
    // 如果文件存在，读取现有设置
    if (exists(settingsPath)) {
        string content = to!string(std.file.read(settingsPath));
        settings = parseJSON(content);
    } else {
        settings = parseJSON("{}");
        mkdirRecurse(dirName(settingsPath));
    }
    
    // 更新或创建 env 对象
    if ("env" !in settings.object) {
        settings["env"] = parseJSON("{}");
    }
    
    // 更新环境变量
    settings["env"]["ANTHROPIC_BASE_URL"] = config.baseUrl;
    settings["env"]["ANTHROPIC_AUTH_TOKEN"] = config.authToken;
    
    // 写入文件
    std.file.write(settingsPath, settings.toPrettyString(JSONOptions.doNotEscapeSlashes));
}

/// Displays the current Claude settings from settings.json
void displayClaudeSettings(string settingsPath) {
    if (exists(settingsPath)) {
        string content = to!string(std.file.read(settingsPath));
        writeln(content);
    }
}

/// Utility struct for accessing environment variables
struct Environment {
    /// Gets the value of an environment variable
    static string get(string name) {
        import core.stdc.stdlib : getenv;
        import std.string : fromStringz;

        auto value = getenv(name.toStringz());
        if (value is null) {
            throw new Exception("Environment variable " ~ name ~ " not found");
        }
        return value.fromStringz().idup;
    }
}
