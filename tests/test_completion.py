import json
import urllib.request
import urllib.error

OLLAMA_API_URL = "http://localhost:11434/api/generate"
MODEL = "qwen2.5-coder:1.5b"

def get_completion(history, current_buffer, local_files="", variant="no_sys"):
    if variant == "no_sys":
        prompt = (
            "Instructions: You are a Fish shell autocompleter.\n"
            "Below is the history of the last 5 commands run in the shell, followed by the current command line buffer.\n"
            "Generate the completion that should be appended to the current command line at the cursor position to complete it.\n"
            "Output ONLY the completion text itself, with no formatting, no markdown, no quotes around it, and no explanation.\n"
            "If no completion is appropriate, output nothing.\n\n"
            "Recent history:\n"
        )
        for cmd in history:
            prompt += f"- {cmd}\n"
        if local_files:
            prompt += f"\nFiles in current directory: {local_files}\n"
        prompt += f"\nCurrent command line:\n{current_buffer}\n\nCompletion:"
        
        payload = {
            "model": MODEL,
            "prompt": prompt,
            "stream": False,
            "options": {
                "num_predict": 50,
                "temperature": 0.0,
                "stop": ["\n"]
            }
        }
    elif variant == "sys_prompt":
        system_prompt = (
            "You are a terminal autocomplete AI. "
            "Your task is to provide the EXACT characters that should be appended to the user's current input. "
            "DO NOT repeat the user's current input. Output ONLY the suffix."
        )
        prompt = "Recent history:\n"
        for cmd in history:
            prompt += f"- {cmd}\n"
        if local_files:
            prompt += f"\nFiles in current directory: {local_files}\n"
        prompt += f"\nCurrent command line:\n{current_buffer}\n\nSuffix to append:"
        
        payload = {
            "model": MODEL,
            "system": system_prompt,
            "prompt": prompt,
            "stream": False,
            "options": {
                "num_predict": 50,
                "temperature": 0.0,
                "stop": ["\n"]
            }
        }
    elif variant == "json_sys_prompt":
        system_prompt = (
            "You are a terminal autocomplete AI. "
            "You must output ONLY a JSON object containing the exact characters to append to the user's input. "
            "Do NOT repeat the user's input. Format: {\"completion\": \"suffix_here\"}"
        )
        prompt = "Recent history:\n"
        for cmd in history:
            prompt += f"- {cmd}\n"
        if local_files:
            prompt += f"\nFiles in current directory: {local_files}\n"
        prompt += f"\nCurrent command line:\n{current_buffer}\n\n"
        
        payload = {
            "model": MODEL,
            "system": system_prompt,
            "prompt": prompt,
            "stream": False,
            "format": "json",
            "options": {
                "num_predict": 50,
                "temperature": 0.0,
                "stop": ["\n"]
            }
        }
    elif variant == "fim":
        # Qwen FIM prompt: <|fim_prefix|>...<|fim_suffix|>...<|fim_middle|>
        prompt = f"<|fim_prefix|>"
        if history:
            prompt += f"# Recent history:\n"
            for cmd in history:
                prompt += f"# - {cmd}\n"
        if local_files:
            prompt += f"# Files in directory: {local_files}\n"
        prompt += f"{current_buffer}<|fim_suffix|><|fim_middle|>"
        
        payload = {
            "model": MODEL,
            "prompt": prompt,
            "raw": True,
            "stream": False,
            "options": {
                "num_predict": 50,
                "temperature": 0.0,
                "stop": ["\n", "<|file_separator|>"]
            }
        }

    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(OLLAMA_API_URL, data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            
            raw_response = ""
            if variant == "json_sys_prompt":
                try:
                    js = json.loads(result.get('response', '{}'))
                    raw_response = js.get("completion", "")
                except json.JSONDecodeError:
                    raw_response = result.get('response', '')
            else:
                raw_response = result.get('response', '')
            
            # Middlelayer logic: if the model repeated the current buffer, slice it off
            if raw_response.startswith(current_buffer):
                raw_response = raw_response[len(current_buffer):]
            else:
                # check if it repeated the last word
                words = current_buffer.split()
                if words and raw_response.startswith(words[-1]):
                    raw_response = raw_response[len(words[-1]):]
            
            return raw_response
            
    except Exception as e:
        print(f"Error calling ollama: {e}")
        return ""

TEST_CASES = [
    {
        "history": ["git add .", "git status"],
        "buffer": "git comm",
        "local_files": "",
        "expected": "it -m"
    },
    {
        "history": ["cd /tmp", "mkdir test", "cd test"],
        "buffer": "touch in",
        "local_files": "index.html, style.css, script.js",
        "expected": "dex.html"
    },
    {
        "history": ["docker build -t myapp .", "docker run -d -p 8080:80 myapp"],
        "buffer": "docker ps",
        "local_files": "Dockerfile, main.go, go.mod",
        "expected": ""
    }
]

def run_tests():
    print(f"Testing model {MODEL}")
    for i, tc in enumerate(TEST_CASES):
        print(f"\nTest {i+1}:")
        print(f"History: {tc['history']}")
        print(f"Buffer: '{tc['buffer']}'")
        print(f"Local files context: '{tc['local_files']}'")
        
        for variant in ["no_sys", "sys_prompt", "json_sys_prompt", "fim"]:
            res = get_completion(tc['history'], tc['buffer'], local_files=tc['local_files'], variant=variant)
            print(f"  [{variant}] Result: '{res}'")
        
        print(f"  Expected starts with: '{tc['expected']}'")

if __name__ == "__main__":
    run_tests()
