# Dockerfile for Audit container
FROM microsoft/windowsservercore:10.0.14393.2189

LABEL maintainer="John George <john.george@claranet.uk>" \
      readme.md="https://github.com/claranet/windows-audit/README.md" \
      description="This dockerfile will build a container to host Audit scripting."

# Configure the working directory
WORKDIR C:\\claranet-audit

# Configure the container os
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command " \
      Set-WinSystemLocale 'en-GB'; \
      Set-TimeZone 'GMT Standard Time'; \
      winrm s winrm/config/client '@{TrustedHosts=\"*\"}'; \
      Invoke-Expression $(curl https://chocolatey.org/install.ps1 -UseBasicParsing | Select -ExpandProperty Content); \
"
# Configure audit prereqs
RUN powershell -NoProfile -ExecutionPolicy Bypass -Command " \
      choco install -y putty; \
      choco install -y winscp; \
"

# Copy the release build output folder to the container
COPY ./Code/bin/Release/netcoreapp2.0/win10-x64/publish/ ./

# And start the audit application
CMD "claranet-audit.exe"