package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"html/template"
	"os"
	"path/filepath"
)

const tplName = "index"

func main() {
	tplPath := flag.String("template-path-pattern", "templates/**/*.gohtml", "Path to template files")
	contentPath := flag.String("content-path-pattern", "content/*.json", "Path to content files")
	output := flag.String("output", "dist/index.html", "Output path")

	flag.Parse()

	content, err := LoadContent(*contentPath)
	if err != nil {
		panic(err)
	}

	tpl, err := LoadTemplates(*tplPath)
	if err != nil {
		panic(err)
	}

	index, err := os.OpenFile(*output, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		panic(err)
	}
	defer func() { _ = index.Close() }()

	if err := tpl.ExecuteTemplate(index, tplName, content); err != nil {
		panic(err)
	}
}

func LoadContent(pattern string) (map[string]any, error) {
	files, err := filepath.Glob(pattern)
	if err != nil {
		panic(err)
	}

	// What about type safety?
	// it's to generate my personal website, with 2 visits/year. It simpler and more flexible
	var content map[string]any

	for _, file := range files {
		bs, err := os.ReadFile(file)
		if err != nil {
			return nil, fmt.Errorf("failed to read file %s: %w", file, err)
		}

		if err = json.Unmarshal(bs, &content); err != nil {
			return nil, fmt.Errorf("failed to parse file %s: %w", file, err)
		}
	}

	return content, nil
}

func LoadTemplates(pattern string) (*template.Template, error) {
	t := template.New(tplName)

	templates, err := filepath.Glob(pattern)
	if err != nil {
		return nil, fmt.Errorf("failed to load templates: %w", err)
	}

	t, err = t.ParseFiles(templates...)
	if err != nil {
		return nil, fmt.Errorf("failed to parse templates %s: %w", templates, err)
	}

	return t, nil
}
