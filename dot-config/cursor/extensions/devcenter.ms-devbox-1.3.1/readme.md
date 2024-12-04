## Microsoft Dev Box

The [Microsoft Dev Box](https://devbox.microsoft.com/) extension helps you create customization files for your Dev Box. It provides assistance when creating your own original workload.yaml files through validation and allows you to see what customization tasks are available within your Dev Box.

## How to use the extension

1. Open your existing `workload.yaml` file or create a new one from scratch. The name of the file is important because the extension will only validate files of that name.
2. You will automatically see any errors in your file being called out, as well as hover boxes for each parameter that provide more information.

## Intergration with GitHub Copilot Chat (PREVIEW)

The [Microsoft Dev Box](https://devbox.microsoft.com/) extension now offers an intergration with GitHub Copilot Chat to bring some AI features to help to create customization tasks. While this feature is in public preview, we welcome feedback about its usefulness and potential for improvement.

To invoke the Dev Box chat agent, enter @devbox in GitHub Copilot Chat.

Two commands are supported: customize and tasks:

1. "tasks": 

    Provides information about the available tasks in the current Dev Box. Sample comman:

        @devbox /tasks Are there any tasks to clone a repo?


2. "customize": Generates customization tasks based on your commands and the available tasks. Sample command:
            
        @devbox /customize I want to install notepad++ and vscode.


## Learn More About Dev Box

- [What is Microsoft Dev Box?](https://learn.microsoft.com/en-us/azure/dev-box/overview-what-is-microsoft-dev-box?wt.mc_id=mdbservice_acomdoc05_webpage_cnl)
