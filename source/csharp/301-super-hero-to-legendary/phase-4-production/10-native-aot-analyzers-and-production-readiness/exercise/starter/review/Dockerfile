FROM mcr.microsoft.com/dotnet/sdk:latest
WORKDIR /app
COPY . .
ENV ASPNETCORE_ENVIRONMENT=Development
ENV ConnectionStrings__Default="Host=db;Database=shop;Username=postgres;Password=postgres"
EXPOSE 5000
CMD ["dotnet", "run", "--urls", "http://0.0.0.0:5000"]
