# Resume: Personal Website Project

This repository contains the source code and build tools for my personal website, [labesse.fr](https://labesse.fr).

## Documentation

### Project Structure

The website content is located in the `content/` directory. The final `index.html` file is generated using Go templates (found in `templates/`) and the `generate.go` script.

CSS files are generated using the TailwindCSS CLI.

### Development and Build Process

To build the website locally for development:
- Run the command: `make build_dist`
- Open the resulting file: `dist/index.html`

### Integration Testing

To ensure the Nginx configuration works correctly, a test suite is provided in tests/nginx.sh. You can execute these tests by running: `make test_docker`

### Deployment and Publishing

#### Local Docker Build:

To create a production-ready Docker image with a tailored Nginx configuration, run: `make build_docker`

#### Automated Release:

Once development is complete:
- Push your changes and create a new Git tag. 
- Run `make all`.

This command automatically generates the `dist/` directory, builds the Docker image, runs tests, and publishes the image to Docker Hub as `eraac/resume:<tag>`.

## Information

- Is this repository overengineered? Yes.
- Is it obvious that I have limited front-end experience and used GenAI? Yes.
- Was it fun to build? Absolutely.
