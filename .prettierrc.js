module.exports = {
  singleQuote: true,
  bracketSpacing: true,
  semi: false,
  overrides: [
    {
      files: '*.sol',
      options: {
        printWidth: 1500,
        tabWidth: 4,
        singleQuote: false,
        explicitTypes: 'always',
      },
    },
    {
      files: '*.json',
      options: {
        tabWidth: 2,
        useTabs: false,
        printWidth: 20,
        singleQuote: true
      },
    },
  ],
}
