# Godot Mono Build Toggler for Godot 4

Adds a toggle button to the editor toolbar which allows enabling or disabling Mono build by hiding the project's solution file. Useful for projects which use both C# and another language like GDScript, so that you can disable Mono while you're not editing any C# source files.

<img src="screenshot_godot4.png" />

### Installation

1. Clone or download the repository
2. Move the `addons/Mono-Build-Toggler` folder to the `addons` folder within your project directory (`res://addons/Mono-Build-Toggler`)
3. Enable the plugin from the `plugins` tab of the Godot editor project settings

# Original Author

This is a fork from the original Godot 3 [addon by @toasterofbread](https://github.com/toasterofbread/Godot-Mono-Build-Toggler). Since toasterofbread archived the repository, I forked it to migrate it to Godot 4.

# WARNING - Risk of losing custom .NET Solution

If you manually customize your Solution file, there's a risk of losing it if you disable "Mono build" with this addon and manually call "Build" while "Mono build" is disabled.

In most cases you do not have to worry about this possible overwrite, because there are rare cases where one edit a Godot's project .NET Solution file, so no issues are caused by the Solution file being overwritten and you can safely ignore this.

Reproducible steps:
1. Disable "Mono build" with this addon.
1. The addon will create "YourProjectName.sln.disabled" and "YourProjectName.csproj.disabled".
1. While "Mono build" is still disabled if you manually click Godot's "Build Project" (or press `ALT+B`), a fresh Solution will be created.
1. Then let's say you manually update the Solution/
1. As soon as you click the addon "Mono build" toggle, the "*.disabled" files will be renamed back and your customized solution file will be overwritten.

Ideally do not manually build while "Mono build" is toggled off. 