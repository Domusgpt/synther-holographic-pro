Claude
API
Solutions
Research
Commitments
Learn
News
Try Claude
Engineering at Anthropic

Claude Code: Best practices for agentic coding
Published Apr 18, 2025

Claude Code is a command line tool for agentic coding. This post covers tips and tricks that have proven effective for using Claude Code across various codebases, languages, and environments.

We recently released Claude Code, a command line tool for agentic coding. Developed as a research project, Claude Code gives Anthropic engineers and researchers a more native way to integrate Claude into their coding workflows.

Claude Code is intentionally low-level and unopinionated, providing close to raw model access without forcing specific workflows. This design philosophy creates a flexible, customizable, scriptable, and safe power tool. While powerful, this flexibility presents a learning curve for engineers new to agentic coding tools—at least until they develop their own best practices.

This post outlines general patterns that have proven effective, both for Anthropic's internal teams and for external engineers using Claude Code across various codebases, languages, and environments. Nothing in this list is set in stone nor universally applicable; consider these suggestions as starting points. We encourage you to experiment and find what works best for you!

Looking for more detailed information? Our comprehensive documentation at claude.ai/code covers all the features mentioned in this post and provides additional examples, implementation details, and advanced techniques.


1. Customize your setup
Claude Code is an agentic coding assistant that automatically pulls context into prompts. This context gathering consumes time and tokens, but you can optimize it through environment tuning.

a. Create CLAUDE.md files
CLAUDE.md is a special file that Claude automatically pulls into context when starting a conversation. This makes it an ideal place for documenting:

Common bash commands
Core files and utility functions
Code style guidelines
Testing instructions
Repository etiquette (e.g., branch naming, merge vs. rebase, etc.)
Developer environment setup (e.g., pyenv use, which compilers work)
Any unexpected behaviors or warnings particular to the project
Other information you want Claude to remember
There’s no required format for CLAUDE.md files. We recommend keeping them concise and human-readable. For example:

# Bash commands
- npm run build: Build the project
- npm run typecheck: Run the typechecker

# Code style
- Use ES modules (import/export) syntax, not CommonJS (require)
- Destructure imports when possible (eg. import { foo } from 'bar')

# Workflow
- Be sure to typecheck when you’re done making a series of code changes
- Prefer running single tests, and not the whole test suite, for performance

Copy
You can place CLAUDE.md files in several locations:

The root of your repo, or wherever you run claude from (the most common usage). Name it CLAUDE.md and check it into git so that you can share it across sessions and with your team (recommended), or name it CLAUDE.local.md and .gitignore it
Any parent of the directory where you run claude. This is most useful for monorepos, where you might run claude from root/foo, and have CLAUDE.md files in both root/CLAUDE.md and root/foo/CLAUDE.md. Both of these will be pulled into context automatically
Any child of the directory where you run claude. This is the inverse of the above, and in this case, Claude will pull in CLAUDE.md files on demand when you work with files in child directories
Your home folder (~/.claude/CLAUDE.md), which applies it to all your claude sessions
When you run the /init command, Claude will automatically generate a CLAUDE.md for you.

b. Tune your CLAUDE.md files
Your CLAUDE.md files become part of Claude’s prompts, so they should be refined like any frequently used prompt. A common mistake is adding extensive content without iterating on its effectiveness. Take time to experiment and determine what produces the best instruction following from the model.

You can add content to your CLAUDE.md manually or press the # key to give Claude an instruction that it will automatically incorporate into the relevant CLAUDE.md. Many engineers use # frequently to document commands, files, and style guidelines while coding, then include CLAUDE.md changes in commits so team members benefit as well.

At Anthropic, we occasionally run CLAUDE.md files through the prompt improver and often tune instructions (e.g. adding emphasis with "IMPORTANT" or "YOU MUST") to improve adherence.

Claude Code tool allowlist
c. Curate Claude's list of allowed tools
By default, Claude Code requests permission for any action that might modify your system: file writes, many bash commands, MCP tools, etc. We designed Claude Code with this deliberately conservative approach to prioritize safety. You can customize the allowlist to permit additional tools that you know are safe, or to allow potentially unsafe tools that are easy to undo (e.g., file editing, git commit).

There are four ways to manage allowed tools:

Select "Always allow" when prompted during a session.
Use the /permissions command after starting Claude Code to add or remove tools from the allowlist. For example, you can add Edit to always allow file edits, Bash(git commit:*) to allow git commits, or mcp__puppeteer__puppeteer_navigate to allow navigating with the Puppeteer MCP server.
Manually edit your .claude/settings.json or ~/.claude.json (we recommend checking the former into source control to share with your team).
Use the --allowedTools CLI flag for session-specific permissions.
d. If using GitHub, install the gh CLI
Claude knows how to use the gh CLI to interact with GitHub for creating issues, opening pull requests, reading comments, and more. Without gh installed, Claude can still use the GitHub API or MCP server (if you have it installed).

2. Give Claude more tools
Claude has access to your shell environment, where you can build up sets of convenience scripts and functions for it just like you would for yourself. It can also leverage more complex tools through MCP and REST APIs.

a. Use Claude with bash tools
Claude Code inherits your bash environment, giving it access to all your tools. While Claude knows common utilities like unix tools and gh, it won't know about your custom bash tools without instructions:

Tell Claude the tool name with usage examples
Tell Claude to run --help to see tool documentation
Document frequently used tools in CLAUDE.md
b. Use Claude with MCP
Claude Code functions as both an MCP server and client. As a client, it can connect to any number of MCP servers to access their tools in three ways:

In project config (available when running Claude Code in that directory)
In global config (available in all projects)
In a checked-in .mcp.json file (available to anyone working in your codebase). For example, you can add Puppeteer and Sentry servers to your .mcp.json, so that every engineer working on your repo can use these out of the box.
When working with MCP, it can also be helpful to launch Claude with the --mcp-debug flag to help identify configuration issues.

c. Use custom slash commands
For repeated workflows—debugging loops, log analysis, etc.—store prompt templates in Markdown files within the .claude/commands folder. These become available through the slash commands menu when you type /. You can check these commands into git to make them available for the rest of your team.

Custom slash commands can include the special keyword $ARGUMENTS to pass parameters from command invocation.

For example, here’s a slash command that you could use to automatically pull and fix a Github issue:

Please analyze and fix the GitHub issue: $ARGUMENTS.

Follow these steps:

1. Use `gh issue view` to get the issue details
2. Understand the problem described in the issue
3. Search the codebase for relevant files
4. Implement the necessary changes to fix the issue
5. Write and run tests to verify the fix
6. Ensure code passes linting and type checking
7. Create a descriptive commit message
8. Push and create a PR

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.

Copy
Putting the above content into .claude/commands/fix-github-issue.md makes it available as the /project:fix-github-issue command in Claude Code. You could then for example use /project:fix-github-issue 1234 to have Claude fix issue #1234. Similarly, you can add your own personal commands to the ~/.claude/commands folder for commands you want available in all of your sessions.

3. Try common workflows
Claude Code doesn’t impose a specific workflow, giving you the flexibility to use it how you want. Within the space this flexibility affords, several successful patterns for effectively using Claude Code have emerged across our community of users:

a. Explore, plan, code, commit
This versatile workflow suits many problems:

Ask Claude to read relevant files, images, or URLs, providing either general pointers ("read the file that handles logging") or specific filenames ("read logging.py"), but explicitly tell it not to write any code just yet.
This is the part of the workflow where you should consider strong use of subagents, especially for complex problems. Telling Claude to use subagents to verify details or investigate particular questions it might have, especially early on in a conversation or task, tends to preserve context availability without much downside in terms of lost efficiency.
Ask Claude to make a plan for how to approach a specific problem. We recommend using the word "think" to trigger extended thinking mode, which gives Claude additional computation time to evaluate alternatives more thoroughly. These specific phrases are mapped directly to increasing levels of thinking budget in the system: "think" < "think hard" < "think harder" < "ultrathink." Each level allocates progressively more thinking budget for Claude to use.
If the results of this step seem reasonable, you can have Claude create a document or a GitHub issue with its plan so that you can reset to this spot if the implementation (step 3) isn’t what you want.
Ask Claude to implement its solution in code. This is also a good place to ask it to explicitly verify the reasonableness of its solution as it implements pieces of the solution.
Ask Claude to commit the result and create a pull request. If relevant, this is also a good time to have Claude update any READMEs or changelogs with an explanation of what it just did.
Steps #1-#2 are crucial—without them, Claude tends to jump straight to coding a solution. While sometimes that's what you want, asking Claude to research and plan first significantly improves performance for problems requiring deeper thinking upfront.

b. Write tests, commit; code, iterate, commit
This is an Anthropic-favorite workflow for changes that are easily verifiable with unit, integration, or end-to-end tests. Test-driven development (TDD) becomes even more powerful with agentic coding:

Ask Claude to write tests based on expected input/output pairs. Be explicit about the fact that you’re doing test-driven development so that it avoids creating mock implementations, even for functionality that doesn’t exist yet in the codebase.
Tell Claude to run the tests and confirm they fail. Explicitly telling it not to write any implementation code at this stage is often helpful.
Ask Claude to commit the tests when you’re satisfied with them.
Ask Claude to write code that passes the tests, instructing it not to modify the tests. Tell Claude to keep going until all tests pass. It will usually take a few iterations for Claude to write code, run the tests, adjust the code, and run the tests again.
At this stage, it can help to ask it to verify with independent subagents that the implementation isn’t overfitting to the tests
Ask Claude to commit the code once you’re satisfied with the changes.
Claude performs best when it has a clear target to iterate against—a visual mock, a test case, or another kind of output. By providing expected outputs like tests, Claude can make changes, evaluate results, and incrementally improve until it succeeds.

c. Write code, screenshot result, iterate
Similar to the testing workflow, you can provide Claude with visual targets:

Give Claude a way to take browser screenshots (e.g., with the Puppeteer MCP server, an iOS simulator MCP server, or manually copy / paste screenshots into Claude).
Give Claude a visual mock by copying / pasting or drag-dropping an image, or giving Claude the image file path.
Ask Claude to implement the design in code, take screenshots of the result, and iterate until its result matches the mock.
Ask Claude to commit when you're satisfied.
Like humans, Claude's outputs tend to improve significantly with iteration. While the first version might be good, after 2-3 iterations it will typically look much better. Give Claude the tools to see its outputs for best results.

Safe yolo mode
d. Safe YOLO mode
Instead of supervising Claude, you can use claude --dangerously-skip-permissions to bypass all permission checks and let Claude work uninterrupted until completion. This works well for workflows like fixing lint errors or generating boilerplate code.

Letting Claude run arbitrary commands is risky and can result in data loss, system corruption, or even data exfiltration (e.g., via prompt injection attacks). To minimize these risks, use --dangerously-skip-permissions in a container without internet access. You can follow this reference implementation using Docker Dev Containers.

e. Codebase Q&A
When onboarding to a new codebase, use Claude Code for learning and exploration. You can ask Claude the same sorts of questions you would ask another engineer on the project when pair programming. Claude can agentically search the codebase to answer general questions like:

How does logging work?
How do I make a new API endpoint?
What does async move { ... } do on line 134 of foo.rs?
What edge cases does CustomerOnboardingFlowImpl handle?
Why are we calling foo() instead of bar() on line 333?
What’s the equivalent of line 334 of baz.py in Java?
At Anthropic, using Claude Code in this way has become our core onboarding workflow, significantly improving ramp-up time and reducing load on other engineers. No special prompting is required! Simply ask questions, and Claude will explore the code to find answers.

Use Claude to interact with git
f. Use Claude to interact with git
Claude can effectively handle many git operations. Many Anthropic engineers use Claude for 90%+ of our git interactions:

Searching git history to answer questions like "What changes made it into v1.2.3?", "Who owns this particular feature?", or "Why was this API designed this way?" It helps to explicitly prompt Claude to look through git history to answer queries like these.
Writing commit messages. Claude will look at your changes and recent history automatically to compose a message taking all the relevant context into account
Handling complex git operations like reverting files, resolving rebase conflicts, and comparing and grafting patches
g. Use Claude to interact with GitHub
Claude Code can manage many GitHub interactions:

Creating pull requests: Claude understands the shorthand "pr" and will generate appropriate commit messages based on the diff and surrounding context.
Implementing one-shot resolutions for simple code review comments: just tell it to fix comments on your PR (optionally, give it more specific instructions) and push back to the PR branch when it's done.
Fixing failing builds or linter warnings
Categorizing and triaging open issues by asking Claude to loop over open GitHub issues
This eliminates the need to remember gh command line syntax while automating routine tasks.

h. Use Claude to work with Jupyter notebooks
Researchers and data scientists at Anthropic use Claude Code to read and write Jupyter notebooks. Claude can interpret outputs, including images, providing a fast way to explore and interact with data. There are no required prompts or workflows, but a workflow we recommend is to have Claude Code and a .ipynb file open side-by-side in VS Code.

You can also ask Claude to clean up or make aesthetic improvements to your Jupyter notebook before you show it to colleagues. Specifically telling it to make the notebook or its data visualizations “aesthetically pleasing” tends to help remind it that it’s optimizing for a human viewing experience.

4. Optimize your workflow
The suggestions below apply across all workflows:

a. Be specific in your instructions
Claude Code’s success rate improves significantly with more specific instructions, especially on first attempts. Giving clear directions upfront reduces the need for course corrections later.

For example:

Poor	Good
add tests for foo.py	write a new test case for foo.py, covering the edge case where the user is logged out. avoid mocks
why does ExecutionFactory have such a weird api?	look through ExecutionFactory's git history and summarize how its api came to be
add a calendar widget	look at how existing widgets are implemented on the home page to understand the patterns and specifically how code and interfaces are separated out. HotDogWidget.php is a good example to start with. then, follow the pattern to implement a new calendar widget that lets the user select a month and paginate forwards/backwards to pick a year. Build from scratch without libraries other than the ones already used in the rest of the codebase.
Claude can infer intent, but it can't read minds. Specificity leads to better alignment with expectations.

Give Claude images
b. Give Claude images
Claude excels with images and diagrams through several methods:

Paste screenshots (pro tip: hit cmd+ctrl+shift+4 in macOS to screenshot to clipboard and ctrl+v to paste. Note that this is not cmd+v like you would usually use to paste on mac and does not work remotely.)
Drag and drop images directly into the prompt input
Provide file paths for images
This is particularly useful when working with design mocks as reference points for UI development, and visual charts for analysis and debugging. If you are not adding visuals to context, it can still be helpful to be clear with Claude about how important it is for the result to be visually appealing.

Mention files you want Claude to look at or work on
c. Mention files you want Claude to look at or work on
Use tab-completion to quickly reference files or folders anywhere in your repository, helping Claude find or update the right resources.

Give Claude URLs
d. Give Claude URLs
Paste specific URLs alongside your prompts for Claude to fetch and read. To avoid permission prompts for the same domains (e.g., docs.foo.com), use /permissions to add domains to your allowlist.

e. Course correct early and often
While auto-accept mode (shift+tab to toggle) lets Claude work autonomously, you'll typically get better results by being an active collaborator and guiding Claude's approach. You can get the best results by thoroughly explaining the task to Claude at the beginning, but you can also course correct Claude at any time.

These four tools help with course correction:

Ask Claude to make a plan before coding. Explicitly tell it not to code until you’ve confirmed its plan looks good.
Press Escape to interrupt Claude during any phase (thinking, tool calls, file edits), preserving context so you can redirect or expand instructions.
Double-tap Escape to jump back in history, edit a previous prompt, and explore a different direction. You can edit the prompt and repeat until you get the result you're looking for.
Ask Claude to undo changes, often in conjunction with option #2 to take a different approach.
Though Claude Code occasionally solves problems perfectly on the first attempt, using these correction tools generally produces better solutions faster.

f. Use /clear to keep context focused
During long sessions, Claude's context window can fill with irrelevant conversation, file contents, and commands. This can reduce performance and sometimes distract Claude. Use the /clear command frequently between tasks to reset the context window.

g. Use checklists and scratchpads for complex workflows
For large tasks with multiple steps or requiring exhaustive solutions—like code migrations, fixing numerous lint errors, or running complex build scripts—improve performance by having Claude use a Markdown file (or even a GitHub issue!) as a checklist and working scratchpad:

For example, to fix a large number of lint issues, you can do the following:

Tell Claude to run the lint command and write all resulting errors (with filenames and line numbers) to a Markdown checklist
Instruct Claude to address each issue one by one, fixing and verifying before checking it off and moving to the next
h. Pass data into Claude
Several methods exist for providing data to Claude:

Copy and paste directly into your prompt (most common approach)
Pipe into Claude Code (e.g., cat foo.txt | claude), particularly useful for logs, CSVs, and large data
Tell Claude to pull data via bash commands, MCP tools, or custom slash commands
Ask Claude to read files or fetch URLs (works for images too)
Most sessions involve a combination of these approaches. For example, you can pipe in a log file, then tell Claude to use a tool to pull in additional context to debug the logs.

5. Use headless mode to automate your infra
Claude Code includes headless mode for non-interactive contexts like CI, pre-commit hooks, build scripts, and automation. Use the -p flag with a prompt to enable headless mode, and --output-format stream-json for streaming JSON output.

Note that headless mode does not persist between sessions. You have to trigger it each session.

a. Use Claude for issue triage
Headless mode can power automations triggered by GitHub events, such as when a new issue is created in your repository. For example, the public Claude Code repository uses Claude to inspect new issues as they come in and assign appropriate labels.

b. Use Claude as a linter
Claude Code can provide subjective code reviews beyond what traditional linting tools detect, identifying issues like typos, stale comments, misleading function or variable names, and more.

6. Uplevel with multi-Claude workflows
Beyond standalone usage, some of the most powerful applications involve running multiple Claude instances in parallel:

a. Have one Claude write code; use another Claude to verify
A simple but effective approach is to have one Claude write code while another reviews or tests it. Similar to working with multiple engineers, sometimes having separate context is beneficial:

Use Claude to write code
Run /clear or start a second Claude in another terminal
Have the second Claude review the first Claude's work
Start another Claude (or /clear again) to read both the code and review feedback
Have this Claude edit the code based on the feedback
You can do something similar with tests: have one Claude write tests, then have another Claude write code to make the tests pass. You can even have your Claude instances communicate with each other by giving them separate working scratchpads and telling them which one to write to and which one to read from.

This separation often yields better results than having a single Claude handle everything.

b. Have multiple checkouts of your repo
Rather than waiting for Claude to complete each step, something many engineers at Anthropic do is:

Create 3-4 git checkouts in separate folders
Open each folder in separate terminal tabs
Start Claude in each folder with different tasks
Cycle through to check progress and approve/deny permission requests
c. Use git worktrees
This approach shines for multiple independent tasks, offering a lighter-weight alternative to multiple checkouts. Git worktrees allow you to check out multiple branches from the same repository into separate directories. Each worktree has its own working directory with isolated files, while sharing the same Git history and reflog.

Using git worktrees enables you to run multiple Claude sessions simultaneously on different parts of your project, each focused on its own independent task. For instance, you might have one Claude refactoring your authentication system while another builds a completely unrelated data visualization component. Since the tasks don't overlap, each Claude can work at full speed without waiting for the other's changes or dealing with merge conflicts:

Create worktrees: git worktree add ../project-feature-a feature-a
Launch Claude in each worktree: cd ../project-feature-a && claude
Create additional worktrees as needed (repeat steps 1-2 in new terminal tabs)
Some tips:

Use consistent naming conventions
Maintain one terminal tab per worktree
If you’re using iTerm2 on Mac, set up notifications for when Claude needs attention
Use separate IDE windows for different worktrees
Clean up when finished: git worktree remove ../project-feature-a
d. Use headless mode with a custom harness
claude -p (headless mode) integrates Claude Code programmatically into larger workflows while leveraging its built-in tools and system prompt. There are two primary patterns for using headless mode:

1. Fanning out handles large migrations or analyses (e.g., analyzing sentiment in hundreds of logs or analyzing thousands of CSVs):

Have Claude write a script to generate a task list. For example, generate a list of 2k files that need to be migrated from framework A to framework B.
Loop through tasks, calling Claude programmatically for each and giving it a task and a set of tools it can use. For example: claude -p “migrate foo.py from React to Vue. When you are done, you MUST return the string OK if you succeeded, or FAIL if the task failed.” --allowedTools Edit Bash(git commit:*)
Run the script several times and refine your prompt to get the desired outcome.
2. Pipelining integrates Claude into existing data/processing pipelines:

Call claude -p “<your prompt>” --json | your_command, where your_command is the next step of your processing pipeline
That’s it! JSON output (optional) can help provide structure for easier automated processing.

//////
# Common workflows

> Learn about common workflows with Claude Code.

Each task in this document includes clear instructions, example commands, and best practices to help you get the most from Claude Code.

## Understand new codebases

### Get a quick codebase overview

Suppose you've just joined a new project and need to understand its structure quickly.

<Steps>
  <Step title="Navigate to the project root directory">
    ```bash
    cd /path/to/project 
    ```
  </Step>

  <Step title="Start Claude Code">
    ```bash
    claude 
    ```
  </Step>

  <Step title="Ask for a high-level overview">
    ```
    > give me an overview of this codebase 
    ```
  </Step>

  <Step title="Dive deeper into specific components">
    ```
    > explain the main architecture patterns used here 
    ```

    ```
    > what are the key data models?
    ```

    ```
    > how is authentication handled?
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Start with broad questions, then narrow down to specific areas
  * Ask about coding conventions and patterns used in the project
  * Request a glossary of project-specific terms
</Tip>

### Find relevant code

Suppose you need to locate code related to a specific feature or functionality.

<Steps>
  <Step title="Ask Claude to find relevant files">
    ```
    > find the files that handle user authentication 
    ```
  </Step>

  <Step title="Get context on how components interact">
    ```
    > how do these authentication files work together? 
    ```
  </Step>

  <Step title="Understand the execution flow">
    ```
    > trace the login process from front-end to database 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Be specific about what you're looking for
  * Use domain language from the project
</Tip>

***

## Fix bugs efficiently

Suppose you've encountered an error message and need to find and fix its source.

<Steps>
  <Step title="Share the error with Claude">
    ```
    > I'm seeing an error when I run npm test 
    ```
  </Step>

  <Step title="Ask for fix recommendations">
    ```
    > suggest a few ways to fix the @ts-ignore in user.ts 
    ```
  </Step>

  <Step title="Apply the fix">
    ```
    > update user.ts to add the null check you suggested 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Tell Claude the command to reproduce the issue and get a stack trace
  * Mention any steps to reproduce the error
  * Let Claude know if the error is intermittent or consistent
</Tip>

***

## Refactor code

Suppose you need to update old code to use modern patterns and practices.

<Steps>
  <Step title="Identify legacy code for refactoring">
    ```
    > find deprecated API usage in our codebase 
    ```
  </Step>

  <Step title="Get refactoring recommendations">
    ```
    > suggest how to refactor utils.js to use modern JavaScript features 
    ```
  </Step>

  <Step title="Apply the changes safely">
    ```
    > refactor utils.js to use ES2024 features while maintaining the same behavior 
    ```
  </Step>

  <Step title="Verify the refactoring">
    ```
    > run tests for the refactored code 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Ask Claude to explain the benefits of the modern approach
  * Request that changes maintain backward compatibility when needed
  * Do refactoring in small, testable increments
</Tip>

***

## Work with tests

Suppose you need to add tests for uncovered code.

<Steps>
  <Step title="Identify untested code">
    ```
    > find functions in NotificationsService.swift that are not covered by tests 
    ```
  </Step>

  <Step title="Generate test scaffolding">
    ```
    > add tests for the notification service 
    ```
  </Step>

  <Step title="Add meaningful test cases">
    ```
    > add test cases for edge conditions in the notification service 
    ```
  </Step>

  <Step title="Run and verify tests">
    ```
    > run the new tests and fix any failures 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Ask for tests that cover edge cases and error conditions
  * Request both unit and integration tests when appropriate
  * Have Claude explain the testing strategy
</Tip>

***

## Create pull requests

Suppose you need to create a well-documented pull request for your changes.

<Steps>
  <Step title="Summarize your changes">
    ```
    > summarize the changes I've made to the authentication module 
    ```
  </Step>

  <Step title="Generate a PR with Claude">
    ```
    > create a pr 
    ```
  </Step>

  <Step title="Review and refine">
    ```
    > enhance the PR description with more context about the security improvements 
    ```
  </Step>

  <Step title="Add testing details">
    ```
    > add information about how these changes were tested 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Ask Claude directly to make a PR for you
  * Review Claude's generated PR before submitting
  * Ask Claude to highlight potential risks or considerations
</Tip>

## Handle documentation

Suppose you need to add or update documentation for your code.

<Steps>
  <Step title="Identify undocumented code">
    ```
    > find functions without proper JSDoc comments in the auth module 
    ```
  </Step>

  <Step title="Generate documentation">
    ```
    > add JSDoc comments to the undocumented functions in auth.js 
    ```
  </Step>

  <Step title="Review and enhance">
    ```
    > improve the generated documentation with more context and examples 
    ```
  </Step>

  <Step title="Verify documentation">
    ```
    > check if the documentation follows our project standards 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Specify the documentation style you want (JSDoc, docstrings, etc.)
  * Ask for examples in the documentation
  * Request documentation for public APIs, interfaces, and complex logic
</Tip>

***

## Use extended thinking

Suppose you're working on complex architectural decisions, challenging bugs, or planning multi-step implementations that require deep reasoning.

<Steps>
  <Step title="Provide context and ask Claude to think">
    ```
    > I need to implement a new authentication system using OAuth2 for our API. Think deeply about the best approach for implementing this in our codebase. 
    ```

    Claude will gather relevant information from your codebase and
    use extended thinking, which will be visible in the interface.
  </Step>

  <Step title="Refine the thinking with follow-up prompts">
    ```
    > think about potential security vulnerabilities in this approach 
    ```

    ```
    > think harder about edge cases we should handle 
    ```
  </Step>
</Steps>

<Tip>
  Tips to get the most value out of extended thinking:

  Extended thinking is most valuable for complex tasks such as:

  * Planning complex architectural changes
  * Debugging intricate issues
  * Creating implementation plans for new features
  * Understanding complex codebases
  * Evaluating tradeoffs between different approaches

  The way you prompt for thinking results in varying levels of thinking depth:

  * "think" triggers basic extended thinking
  * intensifying phrases such as "think more", "think a lot", "think harder", or "think longer" triggers deeper thinking

  For more extended thinking prompting tips, see [Extended thinking tips](/en/docs/build-with-claude/prompt-engineering/extended-thinking-tips).
</Tip>

<Note>
  Claude will display its thinking process as italic gray text above the
  response.
</Note>

***

## Resume previous conversations

Suppose you've been working on a task with Claude Code and need to continue where you left off in a later session.

Claude Code provides two options for resuming previous conversations:

* `--continue` to automatically continue the most recent conversation
* `--resume` to display a conversation picker

<Steps>
  <Step title="Continue the most recent conversation">
    ```bash
    claude --continue
    ```

    This immediately resumes your most recent conversation without any prompts.
  </Step>

  <Step title="Continue in non-interactive mode">
    ```bash
    claude --continue --print "Continue with my task"
    ```

    Use `--print` with `--continue` to resume the most recent conversation in non-interactive mode, perfect for scripts or automation.
  </Step>

  <Step title="Show conversation picker">
    ```bash
    claude --resume
    ```

    This displays an interactive conversation selector showing:

    * Conversation start time
    * Initial prompt or conversation summary
    * Message count

    Use arrow keys to navigate and press Enter to select a conversation.
  </Step>
</Steps>

<Tip>
  Tips:

  * Conversation history is stored locally on your machine
  * Use `--continue` for quick access to your most recent conversation
  * Use `--resume` when you need to select a specific past conversation
  * When resuming, you'll see the entire conversation history before continuing
  * The resumed conversation starts with the same model and configuration as the original

  How it works:

  1. **Conversation Storage**: All conversations are automatically saved locally with their full message history
  2. **Message Deserialization**: When resuming, the entire message history is restored to maintain context
  3. **Tool State**: Tool usage and results from the previous conversation are preserved
  4. **Context Restoration**: The conversation resumes with all previous context intact

  Examples:

  ```bash
  # Continue most recent conversation
  claude --continue

  # Continue most recent conversation with a specific prompt
  claude --continue --print "Show me our progress"

  # Show conversation picker
  claude --resume

  # Continue most recent conversation in non-interactive mode
  claude --continue --print "Run the tests again"
  ```
</Tip>

***

## Run parallel Claude Code sessions with Git worktrees

Suppose you need to work on multiple tasks simultaneously with complete code isolation between Claude Code instances.

<Steps>
  <Step title="Understand Git worktrees">
    Git worktrees allow you to check out multiple branches from the same
    repository into separate directories. Each worktree has its own working
    directory with isolated files, while sharing the same Git history. Learn
    more in the [official Git worktree
    documentation](https://git-scm.com/docs/git-worktree).
  </Step>

  <Step title="Create a new worktree">
    ```bash
    # Create a new worktree with a new branch 
    git worktree add ../project-feature-a -b feature-a

    # Or create a worktree with an existing branch
    git worktree add ../project-bugfix bugfix-123
    ```

    This creates a new directory with a separate working copy of your repository.
  </Step>

  <Step title="Run Claude Code in each worktree">
    ```bash
    # Navigate to your worktree 
    cd ../project-feature-a

    # Run Claude Code in this isolated environment
    claude
    ```
  </Step>

  <Step title="Run Claude in another worktree">
    ```bash
    cd ../project-bugfix
    claude
    ```
  </Step>

  <Step title="Manage your worktrees">
    ```bash
    # List all worktrees
    git worktree list

    # Remove a worktree when done
    git worktree remove ../project-feature-a
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Each worktree has its own independent file state, making it perfect for parallel Claude Code sessions
  * Changes made in one worktree won't affect others, preventing Claude instances from interfering with each other
  * All worktrees share the same Git history and remote connections
  * For long-running tasks, you can have Claude working in one worktree while you continue development in another
  * Use descriptive directory names to easily identify which task each worktree is for
  * Remember to initialize your development environment in each new worktree according to your project's setup. Depending on your stack, this might include:
    * JavaScript projects: Running dependency installation (`npm install`, `yarn`)
    * Python projects: Setting up virtual environments or installing with package managers
    * Other languages: Following your project's standard setup process
</Tip>

***

## Use Claude as a unix-style utility

### Add Claude to your verification process

Suppose you want to use Claude Code as a linter or code reviewer.

**Add Claude to your build script:**

```json
// package.json
{
    ...
    "scripts": {
        ...
        "lint:claude": "claude -p 'you are a linter. please look at the changes vs. main and report any issues related to typos. report the filename and line number on one line, and a description of the issue on the second line. do not return any other text.'"
    }
}
```

<Tip>
  Tips:

  * Use Claude for automated code review in your CI/CD pipeline
  * Customize the prompt to check for specific issues relevant to your project
  * Consider creating multiple scripts for different types of verification
</Tip>

### Pipe in, pipe out

Suppose you want to pipe data into Claude, and get back data in a structured format.

**Pipe data through Claude:**

```bash
cat build-error.txt | claude -p 'concisely explain the root cause of this build error' > output.txt
```

<Tip>
  Tips:

  * Use pipes to integrate Claude into existing shell scripts
  * Combine with other Unix tools for powerful workflows
  * Consider using --output-format for structured output
</Tip>

### Control output format

Suppose you need Claude's output in a specific format, especially when integrating Claude Code into scripts or other tools.

<Steps>
  <Step title="Use text format (default)">
    ```bash
    cat data.txt | claude -p 'summarize this data' --output-format text > summary.txt
    ```

    This outputs just Claude's plain text response (default behavior).
  </Step>

  <Step title="Use JSON format">
    ```bash
    cat code.py | claude -p 'analyze this code for bugs' --output-format json > analysis.json
    ```

    This outputs a JSON array of messages with metadata including cost and duration.
  </Step>

  <Step title="Use streaming JSON format">
    ```bash
    cat log.txt | claude -p 'parse this log file for errors' --output-format stream-json
    ```

    This outputs a series of JSON objects in real-time as Claude processes the request. Each message is a valid JSON object, but the entire output is not valid JSON if concatenated.
  </Step>
</Steps>

<Tip>
  Tips:

  * Use `--output-format text` for simple integrations where you just need Claude's response
  * Use `--output-format json` when you need the full conversation log
  * Use `--output-format stream-json` for real-time output of each conversation turn
</Tip>

***

## Create custom slash commands

Claude Code supports custom slash commands that you can create to quickly execute specific prompts or tasks.

For more details, see the [Slash commands](/en/docs/claude-code/slash-commands) reference page.

### Create project-specific commands

Suppose you want to create reusable slash commands for your project that all team members can use.

<Steps>
  <Step title="Create a commands directory in your project">
    ```bash
    mkdir -p .claude/commands
    ```
  </Step>

  <Step title="Create a Markdown file for each command">
    ```bash
    echo "Analyze the performance of this code and suggest three specific optimizations:" > .claude/commands/optimize.md 
    ```
  </Step>

  <Step title="Use your custom command in Claude Code">
    ```
    > /project:optimize 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Command names are derived from the filename (e.g., `optimize.md` becomes `/project:optimize`)
  * You can organize commands in subdirectories (e.g., `.claude/commands/frontend/component.md` becomes `/project:frontend:component`)
  * Project commands are available to everyone who clones the repository
  * The Markdown file content becomes the prompt sent to Claude when the command is invoked
</Tip>

### Add command arguments with \$ARGUMENTS

Suppose you want to create flexible slash commands that can accept additional input from users.

<Steps>
  <Step title="Create a command file with the $ARGUMENTS placeholder">
    ```bash
    echo "Find and fix issue #$ARGUMENTS. Follow these steps: 1.
    Understand the issue described in the ticket 2. Locate the relevant code in
    our codebase 3. Implement a solution that addresses the root cause 4. Add
    appropriate tests 5. Prepare a concise PR description" >
    .claude/commands/fix-issue.md 
    ```
  </Step>

  <Step title="Use the command with an issue number">
    In your Claude session, use the command with arguments.

    ```
    > /project:fix-issue 123 
    ```

    This will replace \$ARGUMENTS with "123" in the prompt.
  </Step>
</Steps>

<Tip>
  Tips:

  * The \$ARGUMENTS placeholder is replaced with any text that follows the command
  * You can position \$ARGUMENTS anywhere in your command template
  * Other useful applications: generating test cases for specific functions, creating documentation for components, reviewing code in particular files, or translating content to specified languages
</Tip>

### Create personal slash commands

Suppose you want to create personal slash commands that work across all your projects.

<Steps>
  <Step title="Create a commands directory in your home folder">
    ```bash
    mkdir -p ~/.claude/commands 
    ```
  </Step>

  <Step title="Create a Markdown file for each command">
    ```bash
    echo "Review this code for security vulnerabilities, focusing on:" >
    ~/.claude/commands/security-review.md 
    ```
  </Step>

  <Step title="Use your personal custom command">
    ```
    > /user:security-review 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Personal commands are prefixed with `/user:` instead of `/project:`
  * Personal commands are only available to you and not shared with your team
  * Personal commands work across all your projects
  * You can use these for consistent workflows across different codebases
</Tip>

***

## Next steps

<Card title="Claude Code reference implementation" icon="code" href="https://github.com/anthropics/claude-code/tree/main/.devcontainer">
  Clone our development container reference implementation.
</Card>
# Add Claude Code to your IDE

> Learn how to add Claude Code to your favorite IDE

Claude Code seamlessly integrates with popular Integrated Development
Environments (IDEs) to enhance your coding workflow. This integration allows you
to leverage Claude's capabilities directly within your preferred development
environment.

## Supported IDEs

Claude Code currently supports two major IDE families:

* **Visual Studio Code** (including popular forks like Cursor and Windsurf)
* **JetBrains IDEs** (including PyCharm, WebStorm, IntelliJ, and GoLand)

## Features

* **Quick launch**: Use `Cmd+Esc` (Mac) or `Ctrl+Esc` (Windows/Linux) to open
  Claude Code directly from your editor, or click the Claude Code button in the
  UI
* **Diff viewing**: Code changes can be displayed directly in the IDE diff
  viewer instead of the terminal. You can configure this in `/config`
* **Selection context**: The current selection/tab in the IDE is automatically
  shared with Claude Code
* **File reference shortcuts**: Use `Cmd+Option+K` (Mac) or `Alt+Ctrl+K`
  (Linux/Windows) to insert file references (e.g., @File#L1-99)
* **Diagnostic sharing**: Diagnostic errors (lint, syntax, etc.) from the IDE
  are automatically shared with Claude as you work

## Installation

### VS Code

1. Open VSCode
2. Open the integrated terminal
3. Run `claude` - the extension will auto-install

Going forward you can also use the `/ide` command in any external terminal to
connect to the IDE.

<Note>
  These installation instructions also apply to VS Code forks like Cursor and
  Windsurf.
</Note>

### JetBrains IDEs

Install the
[Claude Code plugin](https://docs.anthropic.com/s/claude-code-jetbrains) from
the marketplace and restart your IDE.

<Note>
  The plugin may also be auto-installed when you run `claude` in the integrated
  terminal. The IDE must be restarted completely to take effect.
</Note>

<Warning>
  **Remote Development Limitations**: When using JetBrains Remote Development,
  you must install the plugin in the remote host via `Settings > Plugin (Host)`.
</Warning>

## Configuration

Both integrations work with Claude Code's configuration system. To enable
IDE-specific features:

1. Connect Claude Code to your IDE by running `claude` in the built-in terminal
2. Run the `/config` command
3. Set the diff tool to `auto` for automatic IDE detection
4. Claude Code will automatically use the appropriate viewer based on your IDE

If you're using an external terminal (not the IDE's built-in terminal), you can
still connect to your IDE by using the `/ide` command after launching Claude
Code. This allows you to benefit from IDE integration features even when running
Claude from a separate terminal application. This works for both VS Code and
JetBrains IDEs.

<Note>
  When using an external terminal, to ensure Claude has default access to the
  same files as your IDE, start Claude from the same directory as your IDE
  project root.
</Note>

## Troubleshooting

### VS Code extension not installing

* Ensure you're running Claude Code from VS Code's integrated terminal
* Ensure that the CLI corresponding to your IDE is installed:
  * For VS Code: `code` command should be available
  * For Cursor: `cursor` command should be available
  * For Windsurf: `windsurf` command should be available
  * If not installed, use `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
    and search for "Shell Command: Install 'code' command in PATH" (or the
    equivalent for your IDE)
* Check that VS Code has permission to install extensions

### JetBrains plugin not working

* Ensure you're running Claude Code from the project root directory
* Check that the JetBrains plugin is enabled in the IDE settings
* Completely restart the IDE. You may need to do this multiple times
* For JetBrains Remote Development, ensure that the Claude Code plugin is
  installed in the remote host and not locally on the client

For additional help, refer to our
[troubleshooting guide](/en/docs/claude-code/troubleshooting) or reach out to
support.


//////


# CLI reference

> Complete reference for Claude Code command-line interface, including commands and flags.

## CLI commands

| Command                            | Description                                    | Example                                                            |
| :--------------------------------- | :--------------------------------------------- | :----------------------------------------------------------------- |
| `claude`                           | Start interactive REPL                         | `claude`                                                           |
| `claude "query"`                   | Start REPL with initial prompt                 | `claude "explain this project"`                                    |
| `claude -p "query"`                | Query via SDK, then exit                       | `claude -p "explain this function"`                                |
| `cat file \| claude -p "query"`    | Process piped content                          | `cat logs.txt \| claude -p "explain"`                              |
| `claude -c`                        | Continue most recent conversation              | `claude -c`                                                        |
| `claude -c -p "query"`             | Continue via SDK                               | `claude -c -p "Check for type errors"`                             |
| `claude -r "<session-id>" "query"` | Resume session by ID                           | `claude -r "abc123" "Finish this PR"`                              |
| `claude update`                    | Update to latest version                       | `claude update`                                                    |
| `claude mcp`                       | Configure Model Context Protocol (MCP) servers | See the [Claude Code MCP documentation](/en/docs/claude-code/mcp). |

## CLI flags

Customize Claude Code's behavior with these command-line flags:

| Flag                             | Description                                                                                                                                              | Example                                                     |
| :------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------- |
| `--add-dir`                      | Add additional working directories for Claude to access (validates each path exists as a directory)                                                      | `claude --add-dir ../apps ../lib`                           |
| `--allowedTools`                 | A list of tools that should be allowed without prompting the user for permission, in addition to [settings.json files](/en/docs/claude-code/settings)    | `"Bash(git log:*)" "Bash(git diff:*)" "Write"`              |
| `--disallowedTools`              | A list of tools that should be disallowed without prompting the user for permission, in addition to [settings.json files](/en/docs/claude-code/settings) | `"Bash(git log:*)" "Bash(git diff:*)" "Write"`              |
| `--print`, `-p`                  | Print response without interactive mode (see [SDK documentation](/en/docs/claude-code/sdk) for programmatic usage details)                               | `claude -p "query"`                                         |
| `--output-format`                | Specify output format for print mode (options: `text`, `json`, `stream-json`)                                                                            | `claude -p "query" --output-format json`                    |
| `--input-format`                 | Specify input format for print mode (options: `text`, `stream-json`)                                                                                     | `claude -p --output-format json --input-format stream-json` |
| `--verbose`                      | Enable verbose logging, shows full turn-by-turn output (helpful for debugging in both print and interactive modes)                                       | `claude --verbose`                                          |
| `--max-turns`                    | Limit the number of agentic turns in non-interactive mode                                                                                                | `claude -p --max-turns 3 "query"`                           |
| `--model`                        | Sets the model for the current session with an alias for the latest model (`sonnet` or `opus`) or a model's full name                                    | `claude --model claude-sonnet-4-20250514`                   |
| `--permission-prompt-tool`       | Specify an MCP tool to handle permission prompts in non-interactive mode                                                                                 | `claude -p --permission-prompt-tool mcp_auth_tool "query"`  |
| `--resume`                       | Resume a specific session by ID, or by choosing in interactive mode                                                                                      | `claude --resume abc123 "query"`                            |
| `--continue`                     | Load the most recent conversation in the current directory                                                                                               | `claude --continue`                                         |
| `--dangerously-skip-permissions` | Skip permission prompts (use with caution)                                                                                                               | `claude --dangerously-skip-permissions`                     |

<Tip>
  The `--output-format json` flag is particularly useful for scripting and
  automation, allowing you to parse Claude's responses programmatically.
</Tip>

For detailed information about print mode (`-p`) including output formats,
streaming, verbose logging, and programmatic usage, see the
[SDK documentation](/en/docs/claude-code/sdk).

## See also

* [Interactive mode](/en/docs/claude-code/interactive-mode) - Shortcuts, input modes, and interactive features
* [Slash commands](/en/docs/claude-code/slash-commands) - Interactive session commands
* [Quickstart guide](/en/docs/claude-code/quickstart) - Getting started with Claude Code
* [Common workflows](/en/docs/claude-code/common-workflows) - Advanced workflows and patterns
* [Settings](/en/docs/claude-code/settings) - Configuration options
* [SDK documentation](/en/docs/claude-code/sdk) - Programmatic usage and integrations
/////

# Interactive mode

> Complete reference for keyboard shortcuts, input modes, and interactive features in Claude Code sessions.

## Keyboard shortcuts

### General controls

| Shortcut         | Description                        | Context                    |
| :--------------- | :--------------------------------- | :------------------------- |
| `Ctrl+C`         | Cancel current input or generation | Standard interrupt         |
| `Ctrl+D`         | Exit Claude Code session           | EOF signal                 |
| `Ctrl+L`         | Clear terminal screen              | Keeps conversation history |
| `Up/Down arrows` | Navigate command history           | Recall previous inputs     |

### Multiline input

| Method         | Shortcut       | Context                 |
| :------------- | :------------- | :---------------------- |
| Quick escape   | `\` + `Enter`  | Works in all terminals  |
| macOS default  | `Option+Enter` | Default on macOS        |
| Terminal setup | `Shift+Enter`  | After `/terminal-setup` |
| Paste mode     | Paste directly | For code blocks, logs   |

### Quick commands

| Shortcut     | Description                        | Notes                                                     |
| :----------- | :--------------------------------- | :-------------------------------------------------------- |
| `#` at start | Memory shortcut - add to CLAUDE.md | Prompts for file selection                                |
| `/` at start | Slash command                      | See [slash commands](/en/docs/claude-code/slash-commands) |

## Vim mode

Enable vim-style editing with `/vim` command or configure permanently via `/config`.

### Mode switching

| Command | Action                      | From mode |
| :------ | :-------------------------- | :-------- |
| `Esc`   | Enter NORMAL mode           | INSERT    |
| `i`     | Insert before cursor        | NORMAL    |
| `I`     | Insert at beginning of line | NORMAL    |
| `a`     | Insert after cursor         | NORMAL    |
| `A`     | Insert at end of line       | NORMAL    |
| `o`     | Open line below             | NORMAL    |
| `O`     | Open line above             | NORMAL    |

### Navigation (NORMAL mode)

| Command         | Action                    |
| :-------------- | :------------------------ |
| `h`/`j`/`k`/`l` | Move left/down/up/right   |
| `w`             | Next word                 |
| `e`             | End of word               |
| `b`             | Previous word             |
| `0`             | Beginning of line         |
| `$`             | End of line               |
| `^`             | First non-blank character |
| `gg`            | Beginning of input        |
| `G`             | End of input              |

### Editing (NORMAL mode)

| Command        | Action                  |
| :------------- | :---------------------- |
| `x`            | Delete character        |
| `dd`           | Delete line             |
| `D`            | Delete to end of line   |
| `dw`/`de`/`db` | Delete word/to end/back |
| `cc`           | Change line             |
| `C`            | Change to end of line   |
| `cw`/`ce`/`cb` | Change word/to end/back |
| `.`            | Repeat last change      |

<Tip>
  Configure your preferred line break behavior in terminal settings. Run `/terminal-setup` to install Shift+Enter binding for iTerm2 and VSCode terminals.
</Tip>

## Command history

Claude Code maintains command history for the current session:

* History is stored per working directory
* Cleared with `/clear` command
* Use Up/Down arrows to navigate (see keyboard shortcuts above)
* **Ctrl+R**: Reverse search through history (if supported by terminal)
* **Note**: History expansion (`!`) is disabled by default

## See also

* [Slash commands](/en/docs/claude-code/slash-commands) - Interactive session commands
* [CLI reference](/en/docs/claude-code/cli-reference) - Command-line flags and options
* [Settings](/en/docs/claude-code/settings) - Configuration options
* [Memory management](/en/docs/claude-code/memory) - Managing CLAUDE.md files

/////

# Slash commands

> Control Claude's behavior during an interactive session with slash commands.

## Built-in slash commands

| Command                   | Purpose                                                                        |
| :------------------------ | :----------------------------------------------------------------------------- |
| `/bug`                    | Report bugs (sends conversation to Anthropic)                                  |
| `/clear`                  | Clear conversation history                                                     |
| `/compact [instructions]` | Compact conversation with optional focus instructions                          |
| `/config`                 | View/modify configuration                                                      |
| `/cost`                   | Show token usage statistics                                                    |
| `/doctor`                 | Checks the health of your Claude Code installation                             |
| `/help`                   | Get usage help                                                                 |
| `/init`                   | Initialize project with CLAUDE.md guide                                        |
| `/login`                  | Switch Anthropic accounts                                                      |
| `/logout`                 | Sign out from your Anthropic account                                           |
| `/memory`                 | Edit CLAUDE.md memory files                                                    |
| `/model`                  | Select or change the AI model                                                  |
| `/permissions`            | View or update [permissions](/en/docs/claude-code/iam#configuring-permissions) |
| `/pr_comments`            | View pull request comments                                                     |
| `/review`                 | Request code review                                                            |
| `/status`                 | View account and system statuses                                               |
| `/terminal-setup`         | Install Shift+Enter key binding for newlines (iTerm2 and VSCode only)          |
| `/vim`                    | Enter vim mode for alternating insert and command modes                        |

## Custom slash commands

Custom slash commands allow you to define frequently-used prompts as Markdown files that Claude Code can execute. Commands are organized by scope (project-specific or personal) and support namespacing through directory structures.

### Syntax

```
/<prefix>:<command-name> [arguments]
```

#### Parameters

| Parameter        | Description                                                         |
| :--------------- | :------------------------------------------------------------------ |
| `<prefix>`       | Command scope (`project` for project-specific, `user` for personal) |
| `<command-name>` | Name derived from the Markdown filename (without `.md` extension)   |
| `[arguments]`    | Optional arguments passed to the command                            |

### Command types

#### Project commands

Commands stored in your repository and shared with your team.

**Location**: `.claude/commands/`\
**Prefix**: `/project:`

In the following example, we create the `/project:optimize` command:

```bash
# Create a project command
mkdir -p .claude/commands
echo "Analyze this code for performance issues and suggest optimizations:" > .claude/commands/optimize.md
```

#### Personal commands

Commands available across all your projects.

**Location**: `~/.claude/commands/`\
**Prefix**: `/user:`

In the following example, we create the  `/user:security-review` command:

```bash
# Create a personal command
mkdir -p ~/.claude/commands
echo "Review this code for security vulnerabilities:" > ~/.claude/commands/security-review.md
```

### Features

#### Namespacing

Organize commands in subdirectories to create namespaced commands.

**Structure**: `<prefix>:<namespace>:<command>`

For example, a file at `.claude/commands/frontend/component.md` creates the command `/project:frontend:component`

#### Arguments

Pass dynamic values to commands using the `$ARGUMENTS` placeholder.

For example:

```bash
# Command definition
echo "Fix issue #$ARGUMENTS following our coding standards" > .claude/commands/fix-issue.md

# Usage
> /project:fix-issue 123
```

### File format

Command files must:

* Use Markdown format (`.md` extension)
* Contain the prompt or instructions as file content
* Be placed in the appropriate commands directory

## See also

* [Interactive mode](/en/docs/claude-code/interactive-mode) - Shortcuts, input modes, and interactive features
* [CLI reference](/en/docs/claude-code/cli-reference) - Command-line flags and options
* [Settings](/en/docs/claude-code/settings) - Configuration options
* [Memory management](/en/docs/claude-code/memory) - Managing Claude's memory across sessions
////


# Model Context Protocol (MCP)

> Learn how to set up MCP with Claude Code.

Model Context Protocol (MCP) is an open protocol that enables LLMs to access external tools and data sources. For more details about MCP, see the [MCP documentation](https://modelcontextprotocol.io/introduction).

<Warning>
  Use third party MCP servers at your own risk. Make sure you trust the MCP
  servers, and be especially careful when using MCP servers that talk to the
  internet, as these can expose you to prompt injection risk.
</Warning>

## Configure MCP servers

<Steps>
  <Step title="Add an MCP stdio Server">
    ```bash
    # Basic syntax
    claude mcp add <name> <command> [args...]

    # Example: Adding a local server
    claude mcp add my-server -e API_KEY=123 -- /path/to/server arg1 arg2
    ```
  </Step>

  <Step title="Add an MCP SSE Server">
    ```bash
    # Basic syntax
    claude mcp add --transport sse <name> <url>

    # Example: Adding an SSE server
    claude mcp add --transport sse sse-server https://example.com/sse-endpoint
    ```
  </Step>

  <Step title="Manage your MCP servers">
    ```bash
    # List all configured servers
    claude mcp list

    # Get details for a specific server
    claude mcp get my-server

    # Remove a server
    claude mcp remove my-server
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Use the `-s` or `--scope` flag to specify where the configuration is stored:
    * `local` (default): Available only to you in the current project (was called `project` in older versions)
    * `project`: Shared with everyone in the project via `.mcp.json` file
    * `user`: Available to you across all projects (was called `global` in older versions)
  * Set environment variables with `-e` or `--env` flags (e.g., `-e KEY=value`)
  * Configure MCP server startup timeout using the MCP\_TIMEOUT environment variable (e.g., `MCP_TIMEOUT=10000 claude` sets a 10-second timeout)
  * Check MCP server status any time using the `/mcp` command within Claude Code
  * MCP follows a client-server architecture where Claude Code (the client) can connect to multiple specialized servers
</Tip>

## Understanding MCP server scopes

MCP servers can be configured at three different scope levels, each serving distinct purposes for managing server accessibility and sharing. Understanding these scopes helps you determine the best way to configure servers for your specific needs.

### Scope hierarchy and precedence

MCP server configurations follow a clear precedence hierarchy. When servers with the same name exist at multiple scopes, the system resolves conflicts by prioritizing local-scoped servers first, followed by project-scoped servers, and finally user-scoped servers. This design ensures that personal configurations can override shared ones when needed.

### Local scope

Local-scoped servers represent the default configuration level and are stored in your project-specific user settings. These servers remain private to you and are only accessible when working within the current project directory. This scope is ideal for personal development servers, experimental configurations, or servers containing sensitive credentials that shouldn't be shared.

```bash
# Add a local-scoped server (default)
claude mcp add my-private-server /path/to/server

# Explicitly specify local scope
claude mcp add my-private-server -s local /path/to/server
```

### Project scope

Project-scoped servers enable team collaboration by storing configurations in a `.mcp.json` file at your project's root directory. This file is designed to be checked into version control, ensuring all team members have access to the same MCP tools and services. When you add a project-scoped server, Claude Code automatically creates or updates this file with the appropriate configuration structure.

```bash
# Add a project-scoped server
claude mcp add shared-server -s project /path/to/server
```

The resulting `.mcp.json` file follows a standardized format:

```json
{
  "mcpServers": {
    "shared-server": {
      "command": "/path/to/server",
      "args": [],
      "env": {}
    }
  }
}
```

For security reasons, Claude Code prompts for approval before using project-scoped servers from `.mcp.json` files. If you need to reset these approval choices, use the `claude mcp reset-project-choices` command.

### User scope

User-scoped servers provide cross-project accessibility, making them available across all projects on your machine while remaining private to your user account. This scope works well for personal utility servers, development tools, or services you frequently use across different projects.

```bash
# Add a user server
claude mcp add my-user-server -s user /path/to/server
```

### Choosing the right scope

Select your scope based on:

* **Local scope**: Personal servers, experimental configurations, or sensitive credentials specific to one project
* **Project scope**: Team-shared servers, project-specific tools, or services required for collaboration
* **User scope**: Personal utilities needed across multiple projects, development tools, or frequently-used services

## Connect to a Postgres MCP server

Suppose you want to give Claude read-only access to a PostgreSQL database for querying and schema inspection.

<Steps>
  <Step title="Add the Postgres MCP server">
    ```bash
    claude mcp add postgres-server /path/to/postgres-mcp-server --connection-string "postgresql://user:pass@localhost:5432/mydb"
    ```
  </Step>

  <Step title="Query your database with Claude">
    ```
    > describe the schema of our users table
    ```

    ```
    > what are the most recent orders in the system?
    ```

    ```
    > show me the relationship between customers and invoices
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * The Postgres MCP server provides read-only access for safety
  * Claude can help you explore database structure and run analytical queries
  * You can use this to quickly understand database schemas in unfamiliar projects
  * Make sure your connection string uses appropriate credentials with minimum required permissions
</Tip>

## Add MCP servers from JSON configuration

Suppose you have a JSON configuration for a single MCP server that you want to add to Claude Code.

<Steps>
  <Step title="Add an MCP server from JSON">
    ```bash
    # Basic syntax
    claude mcp add-json <name> '<json>'

    # Example: Adding a stdio server with JSON configuration
    claude mcp add-json weather-api '{"type":"stdio","command":"/path/to/weather-cli","args":["--api-key","abc123"],"env":{"CACHE_DIR":"/tmp"}}'
    ```
  </Step>

  <Step title="Verify the server was added">
    ```bash
    claude mcp get weather-api
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Make sure the JSON is properly escaped in your shell
  * The JSON must conform to the MCP server configuration schema
  * You can use `-s global` to add the server to your global configuration instead of the project-specific one
</Tip>

## Import MCP servers from Claude Desktop

Suppose you have already configured MCP servers in Claude Desktop and want to use the same servers in Claude Code without manually reconfiguring them.

<Steps>
  <Step title="Import servers from Claude Desktop">
    ```bash
    # Basic syntax 
    claude mcp add-from-claude-desktop 
    ```
  </Step>

  <Step title="Select which servers to import">
    After running the command, you'll see an interactive dialog that allows you to select which servers you want to import.
  </Step>

  <Step title="Verify the servers were imported">
    ```bash
    claude mcp list 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * This feature only works on macOS and Windows Subsystem for Linux (WSL)
  * It reads the Claude Desktop configuration file from its standard location on those platforms
  * Use the `-s global` flag to add servers to your global configuration
  * Imported servers will have the same names as in Claude Desktop
  * If servers with the same names already exist, they will get a numerical suffix (e.g., `server_1`)
</Tip>

## Use Claude Code as an MCP server

Suppose you want to use Claude Code itself as an MCP server that other applications can connect to, providing them with Claude's tools and capabilities.

<Steps>
  <Step title="Start Claude as an MCP server">
    ```bash
    # Basic syntax
    claude mcp serve
    ```
  </Step>

  <Step title="Connect from another application">
    You can connect to Claude Code MCP server from any MCP client, such as Claude Desktop. If you're using Claude Desktop, you can add the Claude Code MCP server using this configuration:

    ```json
    {
      "command": "claude",
      "args": ["mcp", "serve"],
      "env": {}
    }
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * The server provides access to Claude's tools like View, Edit, LS, etc.
  * In Claude Desktop, try asking Claude to read files in a directory, make edits, and more.
  * Note that this MCP server is simply exposing Claude Code's tools to your MCP client, so your own client is responsible for implementing user confirmation for individual tool calls.
</Tip>

////
****IMPORTANT FOR AGENTS******
# Manage Claude's memory

> Learn how to manage Claude Code's memory across sessions with different memory locations and best practices.

Claude Code can remember your preferences across sessions, like style guidelines and common commands in your workflow.

## Determine memory type

Claude Code offers three memory locations, each serving a different purpose:

| Memory Type                | Location              | Purpose                                  | Use Case Examples                                                |
| -------------------------- | --------------------- | ---------------------------------------- | ---------------------------------------------------------------- |
| **Project memory**         | `./CLAUDE.md`         | Team-shared instructions for the project | Project architecture, coding standards, common workflows         |
| **User memory**            | `~/.claude/CLAUDE.md` | Personal preferences for all projects    | Code styling preferences, personal tooling shortcuts             |
| **Project memory (local)** | `./CLAUDE.local.md`   | Personal project-specific preferences    | *(Deprecated, see below)* Your sandbox URLs, preferred test data |

All memory files are automatically loaded into Claude Code's context when launched.

## CLAUDE.md imports

CLAUDE.md files can import additional files using `@path/to/import` syntax. The following example imports 3 files:

```
See @README for project overview and @package.json for available npm commands for this project.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

Both relative and absolute paths are allowed. In particular, importing files in user's home dir is a convenient way for your team members to provide individual instructions that are not checked into the repository. Previously CLAUDE.local.md served a similar purpose, but is now deprecated in favor of imports since they work better across multiple git worktrees.

```
# Individual Preferences
- @~/.claude/my-project-instructions.md
```

To avoid potential collisions, imports are not evaluated inside markdown code spans and code blocks.

```
This code span will not be treated as an import: `@anthropic-ai/claude-code`
```

Imported files can recursively import additional files, with a max-depth of 5 hops. You can see what memory files are loaded by running `/memory` command.

## How Claude looks up memories

Claude Code reads memories recursively: starting in the cwd, Claude Code recurses up to */* and reads any CLAUDE.md or CLAUDE.local.md files it finds. This is especially convenient when working in large repositories where you run Claude Code in *foo/bar/*, and have memories in both *foo/CLAUDE.md* and *foo/bar/CLAUDE.md*.

Claude will also discover CLAUDE.md nested in subtrees under your current working directory. Instead of loading them at launch, they are only included when Claude reads files in those subtrees.

## Quickly add memories with the `#` shortcut

The fastest way to add a memory is to start your input with the `#` character:

```
# Always use descriptive variable names
```

You'll be prompted to select which memory file to store this in.

## Directly edit memories with `/memory`

Use the `/memory` slash command during a session to open any memory file in your system editor for more extensive additions or organization.

## Set up project memory

Suppose you want to set up a CLAUDE.md file to store important project information, conventions, and frequently used commands.

Bootstrap a CLAUDE.md for your codebase with the following command:

```
> /init 
```

<Tip>
  Tips:

  * Include frequently used commands (build, test, lint) to avoid repeated searches
  * Document code style preferences and naming conventions
  * Add important architectural patterns specific to your project
  * CLAUDE.md memories can be used for both instructions shared with your team and for your individual preferences.
</Tip>

## Memory best practices

* **Be specific**: "Use 2-space indentation" is better than "Format code properly".
* **Use structure to organize**: Format each individual memory as a bullet point and group related memories under descriptive markdown headings.
* **Review periodically**: Update memories as your project evolves to ensure Claude is always using the most up to date information and context.
////

# Claude Code settings

> Configure Claude Code with global and project-level settings, and environment variables.

Claude Code offers a variety of settings to configure its behavior to meet your needs. You can configure Claude Code by running the `/config` command when using the interactive REPL.

## Settings files

The `settings.json` file is our official mechanism for configuring Claude
Code through hierarchical settings:

* **User settings** are defined in `~/.claude/settings.json` and apply to all
  projects.
* **Project settings** are saved in your project directory:
  * `.claude/settings.json` for settings that are checked into source control and shared with your team
  * `.claude/settings.local.json` for settings that are not checked in, useful for personal preferences and experimention. Claude Code will configure git to ignore `.claude/settings.local.json` when it is created.
* For enterprise deployments of Claude Code, we also support **enterprise
  managed policy settings**. These take precedence over user and project
  settings. System administrators can deploy policies to
  `/Library/Application Support/ClaudeCode/policies.json` on macOS and
  `/etc/claude-code/policies.json` on Linux and Windows via WSL.

```JSON Example settings.json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl:*)"
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp"
  }
}
```

### Available settings

`settings.json` supports a number of options:

| Key                   | Description                                                                                                                                                                                                    | Example                               |
| :-------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------ |
| `apiKeyHelper`        | Custom script, to be executed in `/bin/sh`, to generate an auth value. This value will generally be sent as `X-Api-Key`, `Authorization: Bearer`, and `Proxy-Authorization: Bearer` headers for model requests | `/bin/generate_temp_api_key.sh`       |
| `cleanupPeriodDays`   | How long to locally retain chat transcripts (default: 30 days)                                                                                                                                                 | `20`                                  |
| `env`                 | Environment variables that will be applied to every session                                                                                                                                                    | `{"FOO": "bar"}`                      |
| `includeCoAuthoredBy` | Whether to include the `co-authored-by Claude` byline in git commits and pull requests (default: `true`)                                                                                                       | `false`                               |
| `permissions`         | `allow` and `deny` keys are a list of [permission rules](/en/docs/claude-code/iam#configuring-permissions)                                                                                                     | `{"allow": [ "Bash(npm run lint)" ]}` |

### Settings precedence

Settings are applied in order of precedence:

1. Enterprise policies (see [IAM documentation](/en/docs/claude-code/iam#enterprise-managed-policy-settings))
2. Command line arguments
3. Local project settings
4. Shared project settings
5. User settings

## Environment variables

Claude Code supports the following environment variables to control its behavior:

<Note>
  All environment variables can also be configured in [`settings.json`](#available-settings). This is useful as a way to automatically set environment variables for each session, or to roll out a set of environment variables for your whole team or organization.
</Note>

| Variable                                   | Purpose                                                                                                                                |
| :----------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------- |
| `ANTHROPIC_API_KEY`                        | API key sent as `X-Api-Key` header, typically for the Claude SDK (for interactive usage, run `/login`)                                 |
| `ANTHROPIC_AUTH_TOKEN`                     | Custom value for the `Authorization` and `Proxy-Authorization` headers (the value you set here will be prefixed with `Bearer `)        |
| `ANTHROPIC_CUSTOM_HEADERS`                 | Custom headers you want to add to the request (in `Name: Value` format)                                                                |
| `ANTHROPIC_MODEL`                          | Name of custom model to use (see [Model Configuration](/en/docs/claude-code/bedrock-vertex-proxies#model-configuration))               |
| `ANTHROPIC_SMALL_FAST_MODEL`               | Name of [Haiku-class model for background tasks](/en/docs/claude-code/costs)                                                           |
| `BASH_DEFAULT_TIMEOUT_MS`                  | Default timeout for long-running bash commands                                                                                         |
| `BASH_MAX_TIMEOUT_MS`                      | Maximum timeout the model can set for long-running bash commands                                                                       |
| `BASH_MAX_OUTPUT_LENGTH`                   | Maximum number of characters in bash outputs before they are middle-truncated                                                          |
| `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` | Return to the original working directory after each Bash command                                                                       |
| `CLAUDE_CODE_API_KEY_HELPER_TTL_MS`        | Interval in milliseconds at which credentials should be refreshed (when using `apiKeyHelper`)                                          |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS`            | Set the maximum number of output tokens for most requests                                                                              |
| `CLAUDE_CODE_USE_BEDROCK`                  | Use Bedrock (see [Bedrock & Vertex](/en/docs/claude-code/bedrock-vertex-proxies))                                                      |
| `CLAUDE_CODE_USE_VERTEX`                   | Use Vertex (see [Bedrock & Vertex](/en/docs/claude-code/bedrock-vertex-proxies))                                                       |
| `CLAUDE_CODE_SKIP_BEDROCK_AUTH`            | Skip AWS authentication for Bedrock (e.g. when using an LLM gateway)                                                                   |
| `CLAUDE_CODE_SKIP_VERTEX_AUTH`             | Skip Google authentication for Vertex (e.g. when using an LLM gateway)                                                                 |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | Equivalent of setting `DISABLE_AUTOUPDATER`, `DISABLE_BUG_COMMAND`, `DISABLE_ERROR_REPORTING`, and `DISABLE_TELEMETRY`                 |
| `DISABLE_AUTOUPDATER`                      | Set to `1` to disable the automatic updater                                                                                            |
| `DISABLE_BUG_COMMAND`                      | Set to `1` to disable the `/bug` command                                                                                               |
| `DISABLE_COST_WARNINGS`                    | Set to `1` to disable cost warning messages                                                                                            |
| `DISABLE_ERROR_REPORTING`                  | Set to `1` to opt out of Sentry error reporting                                                                                        |
| `DISABLE_NON_ESSENTIAL_MODEL_CALLS`        | Set to `1` to disable model calls for non-critical paths like flavor text                                                              |
| `DISABLE_TELEMETRY`                        | Set to `1` to opt out of Statsig telemetry (note that Statsig events do not include user data like code, file paths, or bash commands) |
| `HTTP_PROXY`                               | Specify HTTP proxy server for network connections                                                                                      |
| `HTTPS_PROXY`                              | Specify HTTPS proxy server for network connections                                                                                     |
| `MAX_THINKING_TOKENS`                      | Force a thinking for the model budget                                                                                                  |
| `MCP_TIMEOUT`                              | Timeout in milliseconds for MCP server startup                                                                                         |
| `MCP_TOOL_TIMEOUT`                         | Timeout in milliseconds for MCP tool execution                                                                                         |

## Configuration options

We are in the process of migration global configuration to `settings.json`.

`claude config` will be deprecated in place of [settings.json](#settings-files)

To manage your configurations, use the following commands:

* List settings: `claude config list`
* See a setting: `claude config get <key>`
* Change a setting: `claude config set <key> <value>`
* Push to a setting (for lists): `claude config add <key> <value>`
* Remove from a setting (for lists): `claude config remove <key> <value>`

By default `config` changes your project configuration. To manage your global configuration, use the `--global` (or `-g`) flag.

### Global configuration

To set a global configuration, use `claude config set -g <key> <value>`:

| Key                     | Description                                                      | Example                                                                    |
| :---------------------- | :--------------------------------------------------------------- | :------------------------------------------------------------------------- |
| `autoUpdaterStatus`     | Enable or disable the auto-updater (default: `enabled`)          | `disabled`                                                                 |
| `preferredNotifChannel` | Where you want to receive notifications (default: `iterm2`)      | `iterm2`, `iterm2_with_bell`, `terminal_bell`, or `notifications_disabled` |
| `theme`                 | Color theme                                                      | `dark`, `light`, `light-daltonized`, or `dark-daltonized`                  |
| `verbose`               | Whether to show full bash and command outputs (default: `false`) | `true`                                                                     |

## Tools available to Claude

Claude Code has access to a set of powerful tools that help it understand and modify your codebase:

| Tool             | Description                                          | Permission Required |
| :--------------- | :--------------------------------------------------- | :------------------ |
| **Agent**        | Runs a sub-agent to handle complex, multi-step tasks | No                  |
| **Bash**         | Executes shell commands in your environment          | Yes                 |
| **Edit**         | Makes targeted edits to specific files               | Yes                 |
| **Glob**         | Finds files based on pattern matching                | No                  |
| **Grep**         | Searches for patterns in file contents               | No                  |
| **LS**           | Lists files and directories                          | No                  |
| **MultiEdit**    | Performs multiple edits on a single file atomically  | Yes                 |
| **NotebookEdit** | Modifies Jupyter notebook cells                      | Yes                 |
| **NotebookRead** | Reads and displays Jupyter notebook contents         | No                  |
| **Read**         | Reads the contents of files                          | No                  |
| **TodoRead**     | Reads the current session's task list                | No                  |
| **TodoWrite**    | Creates and manages structured task lists            | No                  |
| **WebFetch**     | Fetches content from a specified URL                 | Yes                 |
| **WebSearch**    | Performs web searches with domain filtering          | Yes                 |
| **Write**        | Creates or overwrites files                          | Yes                 |

Permission rules can be configured using `/allowed-tools` or in [permission settings](/en/docs/claude-code/settings#available-settings).

## See also

* [Identity and Access Management](/en/docs/claude-code/iam#configuring-permissions) - Learn about Claude Code's permission system
* [IAM and access control](/en/docs/claude-code/iam#enterprise-managed-policy-settings) - Enterprise policy management
* [Troubleshooting](/en/docs/claude-code/troubleshooting#auto-updater-issues) - Solutions for common configuration issues
//////


# Security

> Learn about Claude Code's security safeguards and best practices for safe usage.

## How we approach security

### Security foundation

Your code's security is paramount. Claude Code is built with security at its core, developed according to Anthropic's comprehensive security program. Learn more and access resources (SOC 2 Type 2 report, ISO 27001 certificate, etc.) at [Anthropic Trust Center](https://trust.anthropic.com).

### Permission-based architecture

Claude Code uses strict read-only permissions by default. When additional actions are needed (editing files, running tests, executing commands), Claude Code requests explicit permission. Users control whether to approve actions once or allow them automatically.

We designed Claude Code to be transparent and secure. For example, we require approval for `git` commands before executing them, giving you direct control. This approach enables users and organizations to configure permissions directly.

For detailed permission configuration, see [Identity and Access Management](/en/docs/claude-code/iam).

### Built-in protections

To mitigate risks in agentic systems:

* **Prompt fatigue mitigation**: Support for allowlisting frequently used safe commands per-user, per-codebase, or per-organization
* **Accept Edits mode**: Batch accept multiple edits while maintaining permission prompts for commands with side effects

### User responsibility

Claude Code only has the permissions you grant it. You're responsible for reviewing proposed code and commands for safety before approval.

## Protect against prompt injection

Prompt injection is a technique where an attacker attempts to override or manipulate an AI assistant's instructions by inserting malicious text. Claude Code includes several safeguards against these attacks:

### Core protections

* **Permission system**: Sensitive operations require explicit approval
* **Context-aware analysis**: Detects potentially harmful instructions by analyzing the full request
* **Input sanitization**: Prevents command injection by processing user inputs
* **Command blocklist**: Blocks risky commands that fetch arbitrary content from the web like `curl` and `wget`

### Additional safeguards

* **Network request approval**: Tools that make network requests require user approval by default
* **Isolated context windows**: Web fetch uses a separate context window to avoid injecting potentially malicious prompts
* **Trust verification**: First-time codebase runs and new MCP servers require trust verification
* **Command injection detection**: Suspicious bash commands require manual approval even if previously allowlisted
* **Fail-closed matching**: Unmatched commands default to requiring manual approval
* **Natural language descriptions**: Complex bash commands include explanations for user understanding

**Best practices for working with untrusted content**:

1. Review suggested commands before approval
2. Avoid piping untrusted content directly to Claude
3. Verify proposed changes to critical files
4. Report suspicious behavior with `/bug`

<Warning>
  While these protections significantly reduce risk, no system is completely
  immune to all attacks. Always maintain good security practices when working
  with any AI tool.
</Warning>

## MCP security

Claude Code allows users to configure Model Context Protocol (MCP) servers. The list of allowed MCP servers is configured in your source code, as part of Claude Code settings engineers check into source control.

We encourage either writing your own MCP servers or using MCP servers from providers that you trust. You are able to configure Claude Code permissions for MCP servers. Anthropic does not manage or audit any MCP servers.

## Security best practices

### Working with sensitive code

* Review all suggested changes before approval
* Use project-specific permission settings for sensitive repositories
* Consider using [devcontainers](/en/docs/claude-code/devcontainer) for additional isolation
* Regularly audit your permission settings with `/permissions`

### Team security

* Use [enterprise managed policies](/en/docs/claude-code/iam#enterprise-managed-policy-settings) to enforce organizational standards
* Share approved permission configurations through version control
* Train team members on security best practices
* Monitor Claude Code usage through [OpenTelemetry metrics](/en/docs/claude-code/monitoring-usage)

### Reporting security issues

If you discover a security vulnerability in Claude Code:

1. Do not disclose it publicly
2. Report it through our [HackerOne program](https://hackerone.com/anthropic-vdp/reports/new?type=team\&report_type=vulnerability)
3. Include detailed reproduction steps
4. Allow time for us to address the issue before public disclosure

## Related resources

* [Identity and Access Management](/en/docs/claude-code/iam) - Configure permissions and access controls
* [Monitoring usage](/en/docs/claude-code/monitoring-usage) - Track and audit Claude Code activity
* [Development containers](/en/docs/claude-code/devcontainer) - Secure, isolated environments
* [Anthropic Trust Center](https://trust.anthropic.com) - Security certifications and compliance

///////


[look important useful for jules]******

# Claude Code GitHub Actions

> Learn about integrating Claude Code into your development workflow with Claude Code GitHub Actions

Claude Code GitHub Actions brings AI-powered automation to your GitHub workflow. With a simple `@claude` mention in any PR or issue, Claude can analyze your code, create pull requests, implement features, and fix bugs - all while following your project's standards.

<Info>
  Claude Code GitHub Actions is currently in beta. Features and functionality may evolve as we refine the experience.
</Info>

<Note>
  Claude Code GitHub Actions is built on top of the [Claude Code SDK](/en/docs/claude-code/sdk), which enables programmatic integration of Claude Code into your applications. You can use the SDK to build custom automation workflows beyond GitHub Actions.
</Note>

## Why use Claude Code GitHub Actions?

* **Instant PR creation**: Describe what you need, and Claude creates a complete PR with all necessary changes
* **Automated code implementation**: Turn issues into working code with a single command
* **Follows your standards**: Claude respects your `CLAUDE.md` guidelines and existing code patterns
* **Simple setup**: Get started in minutes with our installer and API key
* **Secure by default**: Your code stays on Github's runners

## What can Claude do?

Claude Code provides powerful GitHub Actions that transform how you work with code:

### Claude Code Action

This GitHub Action allows you to run Claude Code within your GitHub Actions workflows. You can use this to build any custom workflow on top of Claude Code.

[View repository →](https://github.com/anthropics/claude-code-action)

### Claude Code Action (Base)

The foundation for building custom GitHub workflows with Claude. This extensible framework gives you full access to Claude's capabilities for creating tailored automation.

[View repository →](https://github.com/anthropics/claude-code-base-action)

## Setup

## Quick setup

The easiest way to set up this action is through Claude Code in the terminal. Just open claude and run `/install-github-app`.

This command will guide you through setting up the GitHub app and required secrets.

<Note>
  * You must be a repository admin to install the GitHub app and add secrets
  * This quickstart method is only available for direct Anthropic API users. If you're using AWS Bedrock or Google Vertex AI, please see the [Using with AWS Bedrock & Google Vertex AI](#using-with-aws-bedrock-%26-google-vertex-ai) section.
</Note>

## Manual setup

If the `/install-github-app` command fails or you prefer manual setup, please follow these manual setup instructions:

1. **Install the Claude GitHub app** to your repository: [https://github.com/apps/claude](https://github.com/apps/claude)
2. **Add ANTHROPIC\_API\_KEY** to your repository secrets ([Learn how to use secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions))
3. **Copy the workflow file** from [examples/claude.yml](https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml) into your repository's `.github/workflows/`

<Tip>
  After completing either the quickstart or manual setup, test the action by tagging `@claude` in an issue or PR comment!
</Tip>

## Example use cases

Claude Code GitHub Actions can help you with a variety of tasks. For complete working examples, see the [examples directory](https://github.com/anthropics/claude-code-action/tree/main/examples).

### Turn issues into PRs

In an issue comment:

```
@claude implement this feature based on the issue description
```

Claude will analyze the issue, write the code, and create a PR for review.

### Get implementation help

In a PR comment:

```
@claude how should I implement user authentication for this endpoint?
```

Claude will analyze your code and provide specific implementation guidance.

### Fix bugs quickly

In an issue:

```yaml
@claude fix the TypeError in the user dashboard component
```

Claude will locate the bug, implement a fix, and create a PR.

## Best practices

### CLAUDE.md configuration

Create a `CLAUDE.md` file in your repository root to define code style guidelines, review criteria, project-specific rules, and preferred patterns. This file guides Claude's understanding of your project standards.

### Security considerations

<Warning>
  Never commit API keys directly to your repository!
</Warning>

Always use GitHub Secrets for API keys:

* Add your API key as a repository secret named `ANTHROPIC_API_KEY`
* Reference it in workflows: `anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}`
* Limit action permissions to only what's necessary
* Review Claude's suggestions before merging

Always use GitHub Secrets (e.g., `${{ secrets.ANTHROPIC_API_KEY }}`) rather than hardcoding API keys directly in your workflow files.

### Optimizing performance

Use issue templates to provide context, keep your `CLAUDE.md` concise and focused, and configure appropriate timeouts for your workflows.

### CI costs

When using Claude Code GitHub Actions, be aware of the associated costs:

**GitHub Actions costs:**

* Claude Code runs on GitHub-hosted runners, which consume your GitHub Actions minutes
* See [GitHub's billing documentation](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions) for detailed pricing and minute limits

**API costs:**

* Each Claude interaction consumes API tokens based on the length of prompts and responses
* Token usage varies by task complexity and codebase size
* See [Claude's pricing page](https://www.anthropic.com/api) for current token rates

**Cost optimization tips:**

* Use specific `@claude` commands to reduce unnecessary API calls
* Configure appropriate `max_turns` limits to prevent excessive iterations
* Set reasonable `timeout_minutes` to avoid runaway workflows
* Consider using GitHub's concurrency controls to limit parallel runs

## Configuration examples

For ready-to-use workflow configurations for different use cases, including:

* Basic workflow setup for issue and PR comments
* Automated code reviews on pull requests
* Custom implementations for specific needs

Visit the [examples directory](https://github.com/anthropics/claude-code-action/tree/main/examples) in the Claude Code Action repository.

<Tip>
  The examples repository includes complete, tested workflows that you can copy directly into your `.github/workflows/` directory.
</Tip>

## Using with AWS Bedrock & Google Vertex AI

For enterprise environments, you can use Claude Code GitHub Actions with your own cloud infrastructure. This approach gives you control over data residency and billing while maintaining the same functionality.

### Prerequisites

Before setting up Claude Code GitHub Actions with cloud providers, you need:

#### For Google Cloud Vertex AI:

1. A Google Cloud Project with Vertex AI enabled
2. Workload Identity Federation configured for GitHub Actions
3. A service account with the required permissions
4. A GitHub App (recommended) or use the default GITHUB\_TOKEN

#### For AWS Bedrock:

1. An AWS account with Amazon Bedrock enabled
2. GitHub OIDC Identity Provider configured in AWS
3. An IAM role with Bedrock permissions
4. A GitHub App (recommended) or use the default GITHUB\_TOKEN

<Steps>
  <Step title="Create a custom GitHub App (Recommended for 3P Providers)">
    For best control and security when using 3P providers like Vertex AI or Bedrock, we recommend creating your own GitHub App:

    1. Go to [https://github.com/settings/apps/new](https://github.com/settings/apps/new)
    2. Fill in the basic information:
       * **GitHub App name**: Choose a unique name (e.g., "YourOrg Claude Assistant")
       * **Homepage URL**: Your organization's website or the repository URL
    3. Configure the app settings:
       * **Webhooks**: Uncheck "Active" (not needed for this integration)
    4. Set the required permissions:
       * **Repository permissions**:
         * Contents: Read & Write
         * Issues: Read & Write
         * Pull requests: Read & Write
    5. Click "Create GitHub App"
    6. After creation, click "Generate a private key" and save the downloaded `.pem` file
    7. Note your App ID from the app settings page
    8. Install the app to your repository:
       * From your app's settings page, click "Install App" in the left sidebar
       * Select your account or organization
       * Choose "Only select repositories" and select the specific repository
       * Click "Install"
    9. Add the private key as a secret to your repository:
       * Go to your repository's Settings → Secrets and variables → Actions
       * Create a new secret named `APP_PRIVATE_KEY` with the contents of the `.pem` file
    10. Add the App ID as a secret:

    * Create a new secret named `APP_ID` with your GitHub App's ID

    <Note>
      This app will be used with the [actions/create-github-app-token](https://github.com/actions/create-github-app-token) action to generate authentication tokens in your workflows.
    </Note>

    **Alternative for Anthropic API or if you don't want to setup your own Github app**: Use the official Anthropic app:

    1. Install from: [https://github.com/apps/claude](https://github.com/apps/claude)
    2. No additional configuration needed for authentication
  </Step>

  <Step title="Configure cloud provider authentication">
    Choose your cloud provider and set up secure authentication:

    <AccordionGroup>
      <Accordion title="AWS Bedrock">
        **Configure AWS to allow GitHub Actions to authenticate securely without storing credentials.**

        > **Security Note**: Use repository-specific configurations and grant only the minimum required permissions.

        **Required Setup**:

        1. **Enable Amazon Bedrock**:
           * Request access to Claude models in Amazon Bedrock
           * For cross-region models, request access in all required regions

        2. **Set up GitHub OIDC Identity Provider**:
           * Provider URL: `https://token.actions.githubusercontent.com`
           * Audience: `sts.amazonaws.com`

        3. **Create IAM Role for GitHub Actions**:
           * Trusted entity type: Web identity
           * Identity provider: `token.actions.githubusercontent.com`
           * Permissions: `AmazonBedrockFullAccess` policy
           * Configure trust policy for your specific repository

        **Required Values**:

        After setup, you'll need:

        * **AWS\_ROLE\_TO\_ASSUME**: The ARN of the IAM role you created

        <Tip>
          OIDC is more secure than using static AWS access keys because credentials are temporary and automatically rotated.
        </Tip>

        See [AWS documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) for detailed OIDC setup instructions.
      </Accordion>

      <Accordion title="Google Vertex AI">
        **Configure Google Cloud to allow GitHub Actions to authenticate securely without storing credentials.**

        > **Security Note**: Use repository-specific configurations and grant only the minimum required permissions.

        **Required Setup**:

        1. **Enable APIs** in your Google Cloud project:
           * IAM Credentials API
           * Security Token Service (STS) API
           * Vertex AI API

        2. **Create Workload Identity Federation resources**:
           * Create a Workload Identity Pool
           * Add a GitHub OIDC provider with:
             * Issuer: `https://token.actions.githubusercontent.com`
             * Attribute mappings for repository and owner
             * **Security recommendation**: Use repository-specific attribute conditions

        3. **Create a Service Account**:
           * Grant only `Vertex AI User` role
           * **Security recommendation**: Create a dedicated service account per repository

        4. **Configure IAM bindings**:
           * Allow the Workload Identity Pool to impersonate the service account
           * **Security recommendation**: Use repository-specific principal sets

        **Required Values**:

        After setup, you'll need:

        * **GCP\_WORKLOAD\_IDENTITY\_PROVIDER**: The full provider resource name
        * **GCP\_SERVICE\_ACCOUNT**: The service account email address

        <Tip>
          Workload Identity Federation eliminates the need for downloadable service account keys, improving security.
        </Tip>

        For detailed setup instructions, consult the [Google Cloud Workload Identity Federation documentation](https://cloud.google.com/iam/docs/workload-identity-federation).
      </Accordion>
    </AccordionGroup>
  </Step>

  <Step title="Add Required Secrets">
    Add the following secrets to your repository (Settings → Secrets and variables → Actions):

    #### For Anthropic API (Direct):

    1. **For API Authentication**:
       * `ANTHROPIC_API_KEY`: Your Anthropic API key from [console.anthropic.com](https://console.anthropic.com)

    2. **For GitHub App (if using your own app)**:
       * `APP_ID`: Your GitHub App's ID
       * `APP_PRIVATE_KEY`: The private key (.pem) content

    #### For Google Cloud Vertex AI

    1. **For GCP Authentication**:
       * `GCP_WORKLOAD_IDENTITY_PROVIDER`
       * `GCP_SERVICE_ACCOUNT`

    2. **For GitHub App (if using your own app)**:
       * `APP_ID`: Your GitHub App's ID
       * `APP_PRIVATE_KEY`: The private key (.pem) content

    #### For AWS Bedrock

    1. **For AWS Authentication**:
       * `AWS_ROLE_TO_ASSUME`

    2. **For GitHub App (if using your own app)**:
       * `APP_ID`: Your GitHub App's ID
       * `APP_PRIVATE_KEY`: The private key (.pem) content
  </Step>

  <Step title="Create workflow files">
    Create GitHub Actions workflow files that integrate with your cloud provider. The examples below show complete configurations for both AWS Bedrock and Google Vertex AI:

    <AccordionGroup>
      <Accordion title="AWS Bedrock workflow">
        **Prerequisites:**

        * AWS Bedrock access enabled with Claude model permissions
        * GitHub configured as an OIDC identity provider in AWS
        * IAM role with Bedrock permissions that trusts GitHub Actions

        **Required GitHub secrets:**

        | Secret Name          | Description                                       |
        | -------------------- | ------------------------------------------------- |
        | `AWS_ROLE_TO_ASSUME` | ARN of the IAM role for Bedrock access            |
        | `APP_ID`             | Your GitHub App ID (from app settings)            |
        | `APP_PRIVATE_KEY`    | The private key you generated for your GitHub App |

        ```yaml
        name: Claude PR Action 

        permissions:
          contents: write
          pull-requests: write
          issues: write
          id-token: write 

        on:
          issue_comment:
            types: [created]
          pull_request_review_comment:
            types: [created]
          issues:
            types: [opened, assigned]

        jobs:
          claude-pr:
            if: |
              (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'issues' && contains(github.event.issue.body, '@claude'))
            runs-on: ubuntu-latest
            env:
              AWS_REGION: us-west-2
            steps:
              - name: Checkout repository
                uses: actions/checkout@v4

              - name: Generate GitHub App token
                id: app-token
                uses: actions/create-github-app-token@v2
                with:
                  app-id: ${{ secrets.APP_ID }}
                  private-key: ${{ secrets.APP_PRIVATE_KEY }}

              - name: Configure AWS Credentials (OIDC)
                uses: aws-actions/configure-aws-credentials@v4
                with:
                  role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
                  aws-region: us-west-2

              - uses: ./.github/actions/claude-pr-action
                with:
                  trigger_phrase: "@claude"
                  timeout_minutes: "60"
                  github_token: ${{ steps.app-token.outputs.token }}
                  use_bedrock: "true"
                  model: "us.anthropic.claude-3-7-sonnet-20250219-v1:0"
        ```

        <Tip>
          The model ID format for Bedrock includes the region prefix (e.g., `us.anthropic.claude...`) and version suffix.
        </Tip>
      </Accordion>

      <Accordion title="Google Vertex AI workflow">
        **Prerequisites:**

        * Vertex AI API enabled in your GCP project
        * Workload Identity Federation configured for GitHub
        * Service account with Vertex AI permissions

        **Required GitHub secrets:**

        | Secret Name                      | Description                                       |
        | -------------------------------- | ------------------------------------------------- |
        | `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider resource name          |
        | `GCP_SERVICE_ACCOUNT`            | Service account email with Vertex AI access       |
        | `APP_ID`                         | Your GitHub App ID (from app settings)            |
        | `APP_PRIVATE_KEY`                | The private key you generated for your GitHub App |

        ```yaml
        name: Claude PR Action

        permissions:
          contents: write
          pull-requests: write
          issues: write
          id-token: write  

        on:
          issue_comment:
            types: [created]
          pull_request_review_comment:
            types: [created]
          issues:
            types: [opened, assigned]

        jobs:
          claude-pr:
            if: |
              (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'issues' && contains(github.event.issue.body, '@claude'))
            runs-on: ubuntu-latest
            steps:
              - name: Checkout repository
                uses: actions/checkout@v4

              - name: Generate GitHub App token
                id: app-token
                uses: actions/create-github-app-token@v2
                with:
                  app-id: ${{ secrets.APP_ID }}
                  private-key: ${{ secrets.APP_PRIVATE_KEY }}

              - name: Authenticate to Google Cloud
                id: auth
                uses: google-github-actions/auth@v2
                with:
                  workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
                  service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
              
              - uses: ./.github/actions/claude-pr-action
                with:
                  trigger_phrase: "@claude"
                  timeout_minutes: "60"
                  github_token: ${{ steps.app-token.outputs.token }}
                  use_vertex: "true"
                  model: "claude-3-7-sonnet@20250219"
                env:
                  ANTHROPIC_VERTEX_PROJECT_ID: ${{ steps.auth.outputs.project_id }}
                  CLOUD_ML_REGION: us-east5
                  VERTEX_REGION_CLAUDE_3_7_SONNET: us-east5
        ```

        <Tip>
          The project ID is automatically retrieved from the Google Cloud authentication step, so you don't need to hardcode it.
        </Tip>
      </Accordion>
    </AccordionGroup>
  </Step>
</Steps>

## Troubleshooting

### Claude not responding to @claude commands

Verify the GitHub App is installed correctly, check that workflows are enabled, ensure API key is set in repository secrets, and confirm the comment contains `@claude` (not `/claude`).

### CI not running on Claude's commits

Ensure you're using the GitHub App or custom app (not Actions user), check workflow triggers include the necessary events, and verify app permissions include CI triggers.

### Authentication errors

Confirm API key is valid and has sufficient permissions. For Bedrock/Vertex, check credentials configuration and ensure secrets are named correctly in workflows.

## Advanced configuration

### Action parameters

The Claude Code Action supports these key parameters:

| Parameter           | Description                    | Required |
| ------------------- | ------------------------------ | -------- |
| `prompt`            | The prompt to send to Claude   | Yes\*    |
| `prompt_file`       | Path to file containing prompt | Yes\*    |
| `anthropic_api_key` | Anthropic API key              | Yes\*\*  |
| `max_turns`         | Maximum conversation turns     | No       |
| `timeout_minutes`   | Execution timeout              | No       |

\*Either `prompt` or `prompt_file` required\
\*\*Required for direct Anthropic API, not for Bedrock/Vertex

### Alternative integration methods

While the `/install-github-app` command is the recommended approach, you can also:

* **Custom GitHub App**: For organizations needing branded usernames or custom authentication flows. Create your own GitHub App with required permissions (contents, issues, pull requests) and use the actions/create-github-app-token action to generate tokens in your workflows.
* **Manual GitHub Actions**: Direct workflow configuration for maximum flexibility
* **MCP Configuration**: Dynamic loading of Model Context Protocol servers

See the [Claude Code Action repository](https://github.com/anthropics/claude-code-action) for detailed documentation.

### Customizing Claude's behavior

You can configure Claude's behavior in two ways:

1. **CLAUDE.md**: Define coding standards, review criteria, and project-specific rules in a `CLAUDE.md` file at the root of your repository. Claude will follow these guidelines when creating PRs and responding to requests. Check out our [Memory documentation](/en/docs/claude-code/memory) for more details.
2. **Custom prompts**: Use the `prompt` parameter in the workflow file to provide workflow-specific instructions. This allows you to customize Claude's behavior for different workflows or tasks.

Claude will follow these guidelines when creating PRs and responding to requests.
//////
(advanced but mYBE USEFUL)
# Claude Code SDK

> Learn about programmatically integrating Claude Code into your applications with the Claude Code SDK.

The Claude Code SDK enables running Claude Code as a subprocess, providing a way to build AI-powered coding assistants and tools that leverage Claude's capabilities.

The SDK is available for command line, TypeScript, and Python usage.

## Authentication

To use the Claude Code SDK, we recommend creating a dedicated API key:

1. Create an Anthropic API key in the [Anthropic Console](https://console.anthropic.com/)
2. Then, set the `ANTHROPIC_API_KEY` environment variable. We recommend storing this key securely (eg. using a Github [secret](https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions))

## Basic SDK usage

The Claude Code SDK allows you to use Claude Code in non-interactive mode from your applications.

### Command line

Here are a few basic examples for the command line SDK:

```bash
# Run a single prompt and exit (print mode)
$ claude -p "Write a function to calculate Fibonacci numbers"

# Using a pipe to provide stdin
$ echo "Explain this code" | claude -p

# Output in JSON format with metadata
$ claude -p "Generate a hello world function" --output-format json

# Stream JSON output as it arrives
$ claude -p "Build a React component" --output-format stream-json
```

### TypeScript

The TypeScript SDK is included in the main [`@anthropic-ai/claude-code`](https://www.npmjs.com/package/@anthropic-ai/claude-code) package on NPM:

```ts
import { query, type SDKMessage } from "@anthropic-ai/claude-code";

const messages: SDKMessage[] = [];

for await (const message of query({
  prompt: "Write a haiku about foo.py",
  abortController: new AbortController(),
  options: {
    maxTurns: 3,
  },
})) {
  messages.push(message);
}

console.log(messages);
```

The TypeScript SDK accepts all arguments supported by the command line SDK, as well as:

| Argument                     | Description                         | Default                                                       |
| :--------------------------- | :---------------------------------- | :------------------------------------------------------------ |
| `abortController`            | Abort controller                    | `new AbortController()`                                       |
| `cwd`                        | Current working directory           | `process.cwd()`                                               |
| `executable`                 | Which JavaScript runtime to use     | `node` when running with Node.js, `bun` when running with Bun |
| `executableArgs`             | Arguments to pass to the executable | `[]`                                                          |
| `pathToClaudeCodeExecutable` | Path to the Claude Code executable  | Executable that ships with `@anthropic-ai/claude-code`        |

### Python

The Python SDK is available as [`claude-code-sdk`](https://github.com/anthropics/claude-code-sdk-python) on PyPI:

```bash
pip install claude-code-sdk
```

**Prerequisites:**

* Python 3.10+
* Node.js
* Claude Code CLI: `npm install -g @anthropic-ai/claude-code`

Basic usage:

```python
import anyio
from claude_code_sdk import query, ClaudeCodeOptions, Message

async def main():
    messages: list[Message] = []
    
    async for message in query(
        prompt="Write a haiku about foo.py",
        options=ClaudeCodeOptions(max_turns=3)
    ):
        messages.append(message)
    
    print(messages)

anyio.run(main)
```

The Python SDK accepts all arguments supported by the command line SDK through the `ClaudeCodeOptions` class:

```python
from claude_code_sdk import query, ClaudeCodeOptions
from pathlib import Path

options = ClaudeCodeOptions(
    max_turns=3,
    system_prompt="You are a helpful assistant",
    cwd=Path("/path/to/project"),  # Can be string or Path
    allowed_tools=["Read", "Write", "Bash"],
    permission_mode="acceptEdits"
)

async for message in query(prompt="Hello", options=options):
    print(message)
```

## Advanced usage

The documentation below uses the command line SDK as an example, but can also be used with the TypeScript and Python SDKs.

### Multi-turn conversations

For multi-turn conversations, you can resume conversations or continue from the most recent session:

```bash
# Continue the most recent conversation
$ claude --continue

# Continue and provide a new prompt
$ claude --continue "Now refactor this for better performance"

# Resume a specific conversation by session ID
$ claude --resume 550e8400-e29b-41d4-a716-446655440000

# Resume in print mode (non-interactive)
$ claude -p --resume 550e8400-e29b-41d4-a716-446655440000 "Update the tests"

# Continue in print mode (non-interactive)
$ claude -p --continue "Add error handling"
```

### Custom system prompts

You can provide custom system prompts to guide Claude's behavior:

```bash
# Override system prompt (only works with --print)
$ claude -p "Build a REST API" --system-prompt "You are a senior backend engineer. Focus on security, performance, and maintainability."

# System prompt with specific requirements
$ claude -p "Create a database schema" --system-prompt "You are a database architect. Use PostgreSQL best practices and include proper indexing."
```

You can also append instructions to the default system prompt:

```bash
# Append system prompt (only works with --print)
$ claude -p "Build a REST API" --append-system-prompt "After writing code, be sure to code review yourself."
```

### MCP Configuration

The Model Context Protocol (MCP) allows you to extend Claude Code with additional tools and resources from external servers. Using the `--mcp-config` flag, you can load MCP servers that provide specialized capabilities like database access, API integrations, or custom tooling.

Create a JSON configuration file with your MCP servers:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/allowed/files"
      ]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    }
  }
}
```

Then use it with Claude Code:

```bash
# Load MCP servers from configuration
$ claude -p "List all files in the project" --mcp-config mcp-servers.json

# Important: MCP tools must be explicitly allowed using --allowedTools
# MCP tools follow the format: mcp__$serverName__$toolName
$ claude -p "Search for TODO comments" \
  --mcp-config mcp-servers.json \
  --allowedTools "mcp__filesystem__read_file,mcp__filesystem__list_directory"

# Use an MCP tool for handling permission prompts in non-interactive mode
$ claude -p "Deploy the application" \
  --mcp-config mcp-servers.json \
  --allowedTools "mcp__permissions__approve" \
  --permission-prompt-tool mcp__permissions__approve
```

<Note>
  When using MCP tools, you must explicitly allow them using the `--allowedTools` flag. MCP tool names follow the pattern `mcp__<serverName>__<toolName>` where:

  * `serverName` is the key from your MCP configuration file
  * `toolName` is the specific tool provided by that server

  This security measure ensures that MCP tools are only used when explicitly permitted.

  If you specify just the server name (i.e., `mcp__<serverName>`), all tools from that server will be allowed.

  Glob patterns (e.g., `mcp__go*`) are not supported.
</Note>

### Custom permission prompt tool

Optionally, use `--permission-prompt-tool` to pass in an MCP tool that we will use to check whether or not the user grants the model permissions to invoke a given tool. When the model invokes a tool the following happens:

1. We first check permission settings: all [settings.json files](/en/docs/claude-code/settings), as well as `--allowedTools` and `--disallowedTools` passed into the SDK; if one of these allows or denies the tool call, we proceed with the tool call
2. Otherwise, we invoke the MCP tool you provided in `--permission-prompt-tool`

The `--permission-prompt-tool` MCP tool is passed the tool name and input, and must return a JSON-stringified payload with the result. The payload must be one of:

```ts
// tool call is allowed
{
  "behavior": "allow",
  "updatedInput": {...}, // updated input, or just return back the original input
}

// tool call is denied
{
  "behavior": "deny",
  "message": "..." // human-readable string explaining why the permission was denied
}
```

For example, a TypeScript MCP permission prompt tool implementation might look like this:

```ts
const server = new McpServer({
  name: "Test permission prompt MCP Server",
  version: "0.0.1",
});

server.tool(
  "approval_prompt",
  'Simulate a permission check - approve if the input contains "allow", otherwise deny',
  {
    tool_name: z.string().describe("The tool requesting permission"),
    input: z.object({}).passthrough().describe("The input for the tool"),
  },
  async ({ tool_name, input }) => {
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            JSON.stringify(input).includes("allow")
              ? {
                  behavior: "allow",
                  updatedInput: input,
                }
              : {
                  behavior: "deny",
                  message: "Permission denied by test approval_prompt tool",
                }
          ),
        },
      ],
    };
  }
);
```

To use this tool, add your MCP server (eg. with `--mcp-config`), then invoke the SDK like so:

```sh
claude -p "..." \
  --permission-prompt-tool mcp__test-server__approval_prompt \
  --mcp-config my-config.json
```

Usage notes:

* Use `updatedInput` to tell the model that the permission prompt mutated its input; otherwise, set `updatedInput` to the original input, as in the example above. For example, if the tool shows a file edit diff to the user and lets them edit the diff manually, the permission prompt tool should return that updated edit.
* The payload must be JSON-stringified

## Available CLI options

The SDK leverages all the CLI options available in Claude Code. Here are the key ones for SDK usage:

| Flag                       | Description                                                                                            | Example                                                                                                                   |
| :------------------------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------ |
| `--print`, `-p`            | Run in non-interactive mode                                                                            | `claude -p "query"`                                                                                                       |
| `--output-format`          | Specify output format (`text`, `json`, `stream-json`)                                                  | `claude -p --output-format json`                                                                                          |
| `--resume`, `-r`           | Resume a conversation by session ID                                                                    | `claude --resume abc123`                                                                                                  |
| `--continue`, `-c`         | Continue the most recent conversation                                                                  | `claude --continue`                                                                                                       |
| `--verbose`                | Enable verbose logging                                                                                 | `claude --verbose`                                                                                                        |
| `--max-turns`              | Limit agentic turns in non-interactive mode                                                            | `claude --max-turns 3`                                                                                                    |
| `--system-prompt`          | Override system prompt (only with `--print`)                                                           | `claude --system-prompt "Custom instruction"`                                                                             |
| `--append-system-prompt`   | Append to system prompt (only with `--print`)                                                          | `claude --append-system-prompt "Custom instruction"`                                                                      |
| `--allowedTools`           | Space-separated list of allowed tools, or <br /><br /> string of comma-separated list of allowed tools | `claude --allowedTools mcp__slack mcp__filesystem`<br /><br />`claude --allowedTools "Bash(npm install),mcp__filesystem"` |
| `--disallowedTools`        | Space-separated list of denied tools, or <br /><br /> string of comma-separated list of denied tools   | `claude --disallowedTools mcp__splunk mcp__github`<br /><br />`claude --disallowedTools "Bash(git commit),mcp__github"`   |
| `--mcp-config`             | Load MCP servers from a JSON file                                                                      | `claude --mcp-config servers.json`                                                                                        |
| `--permission-prompt-tool` | MCP tool for handling permission prompts (only with `--print`)                                         | `claude --permission-prompt-tool mcp__auth__prompt`                                                                       |

For a complete list of CLI options and features, see the [CLI reference](/en/docs/claude-code/cli-reference) documentation.

## Output formats

The SDK supports multiple output formats:

### Text output (default)

Returns just the response text:

```bash
$ claude -p "Explain file src/components/Header.tsx"
# Output: This is a React component showing...
```

### JSON output

Returns structured data including metadata:

```bash
$ claude -p "How does the data layer work?" --output-format json
```

Response format:

```json
{
  "type": "result",
  "subtype": "success",
  "total_cost_usd": 0.003,
  "is_error": false,
  "duration_ms": 1234,
  "duration_api_ms": 800,
  "num_turns": 6,
  "result": "The response text here...",
  "session_id": "abc123"
}
```

### Streaming JSON output

Streams each message as it is received:

```bash
$ claude -p "Build an application" --output-format stream-json
```

Each conversation begins with an initial `init` system message, followed by a list of user and assistant messages, followed by a final `result` system message with stats. Each message is emitted as a separate JSON object.

## Message schema

Messages returned from the JSON API are strictly typed according to the following schema:

```ts
type SDKMessage =
  // An assistant message
  | {
      type: "assistant";
      message: Message; // from Anthropic SDK
      session_id: string;
    }

  // A user message
  | {
      type: "user";
      message: MessageParam; // from Anthropic SDK
      session_id: string;
    }

  // Emitted as the last message
  | {
      type: "result";
      subtype: "success";
      duration_ms: float;
      duration_api_ms: float;
      is_error: boolean;
      num_turns: int;
      result: string;
      session_id: string;
      total_cost_usd: float;
    }

  // Emitted as the last message, when we've reached the maximum number of turns
  | {
      type: "result";
      subtype: "error_max_turns" | "error_during_execution";
      duration_ms: float;
      duration_api_ms: float;
      is_error: boolean;
      num_turns: int;
      session_id: string;
      total_cost_usd: float;
    }

  // Emitted as the first message at the start of a conversation
  | {
      type: "system";
      subtype: "init";
      apiKeySource: string;
      cwd: string;
      session_id: string;
      tools: string[];
      mcp_servers: {
        name: string;
        status: string;
      }[];
      model: string;
      permissionMode: "default" | "acceptEdits" | "bypassPermissions" | "plan";
    };
```

We will soon publish these types in a JSONSchema-compatible format. We use semantic versioning for the main Claude Code package to communicate breaking changes to this format.

`Message` and `MessageParam` types are available in Anthropic SDKs. For example, see the Anthropic [TypeScript](https://github.com/anthropics/anthropic-sdk-typescript) and [Python](https://github.com/anthropics/anthropic-sdk-python/) SDKs.

## Input formats

The SDK supports multiple input formats:

### Text input (default)

Input text can be provided as an argument:

```bash
$ claude -p "Explain this code"
```

Or input text can be piped via stdin:

```bash
$ echo "Explain this code" | claude -p
```

### Streaming JSON input

A stream of messages provided via `stdin` where each message represents a user turn. This allows multiple turns of a conversation without re-launching the `claude` binary and allows providing guidance to the model while it is processing a request.

Each message is a JSON 'User message' object, following the same format as the output message schema. Messages are formatted using the [jsonl](https://jsonlines.org/) format where each line of input is a complete JSON object. Streaming JSON input requires `-p` and `--output-format stream-json`.

Currently this is limited to text-only user messages.

```bash
$ echo '{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Explain this code"}]}}' | claude -p --output-format=stream-json --input-format=stream-json --verbose
```

## Examples

### Simple script integration

```bash
#!/bin/bash

# Simple function to run Claude and check exit code
run_claude() {
    local prompt="$1"
    local output_format="${2:-text}"

    if claude -p "$prompt" --output-format "$output_format"; then
        echo "Success!"
    else
        echo "Error: Claude failed with exit code $?" >&2
        return 1
    fi
}

# Usage examples
run_claude "Write a Python function to read CSV files"
run_claude "Optimize this database query" "json"
```

### Processing files with Claude

```bash
# Process a file through Claude
$ cat mycode.py | claude -p "Review this code for bugs"

# Process multiple files
$ for file in *.js; do
    echo "Processing $file..."
    claude -p "Add JSDoc comments to this file:" < "$file" > "${file}.documented"
done

# Use Claude in a pipeline
$ grep -l "TODO" *.py | while read file; do
    claude -p "Fix all TODO items in this file" < "$file"
done
```

### Session management

```bash
# Start a session and capture the session ID
$ claude -p "Initialize a new project" --output-format json | jq -r '.session_id' > session.txt

# Continue with the same session
$ claude -p --resume "$(cat session.txt)" "Add unit tests"
```

## Best practices

1. **Use JSON output format** for programmatic parsing of responses:

   ```bash
   # Parse JSON response with jq
   result=$(claude -p "Generate code" --output-format json)
   code=$(echo "$result" | jq -r '.result')
   cost=$(echo "$result" | jq -r '.cost_usd')
   ```

2. **Handle errors gracefully** - check exit codes and stderr:

   ```bash
   if ! claude -p "$prompt" 2>error.log; then
       echo "Error occurred:" >&2
       cat error.log >&2
       exit 1
   fi
   ```

3. **Use session management** for maintaining context in multi-turn conversations

4. **Consider timeouts** for long-running operations:

   ```bash
   timeout 300 claude -p "$complex_prompt" || echo "Timed out after 5 minutes"
   ```

5. **Respect rate limits** when making multiple requests by adding delays between calls

## Real-world applications

The Claude Code SDK enables powerful integrations with your development workflow. One notable example is the [Claude Code GitHub Actions](/en/docs/claude-code/github-actions), which uses the SDK to provide automated code review, PR creation, and issue triage capabilities directly in your GitHub workflow.

## Related resources

* [CLI usage and controls](/en/docs/claude-code/cli-reference) - Complete CLI documentation
* [GitHub Actions integration](/en/docs/claude-code/github-actions) - Automate your GitHub workflow with Claude
* [Common workflows](/en/docs/claude-code/common-workflows) - Step-by-step guides for common use cases
