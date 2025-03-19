# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

ARG TARGETPLATFORM
ARG TARGETARCH
ARG BUILDPLATFORM

# Print platform arguments for debugging
RUN echo "TARGETPLATFORM=${TARGETPLATFORM}" && echo "TARGETARCH=${TARGETARCH}" && echo "BUILDPLATFORM=${BUILDPLATFORM}"

WORKDIR /source

# Copy all source files to /source in the container
COPY . .

# Debug: List the files in /source to ensure Worker.csproj is there
RUN ls -al /source

# Restore dependencies explicitly pointing to the project file
RUN dotnet restore /source/Worker.csproj

# Publish the application by explicitly specifying the project file
RUN dotnet publish /source/Worker.csproj -c Release -o /app -a $TARGETARCH --self-contained=false --no-restore

# Stage 2: Runtime container to run the application
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Worker.dll"]
