module.exports = [
  {
    files: ["**/*.js"],
    ignores: ["node_modules/**"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        console: "readonly",
        exports: "writable",
        module: "readonly",
        require: "readonly",
      },
    },
    rules: {
      "comma-dangle": ["error", "always-multiline"],
      "indent": ["error", 2],
      "no-unused-vars": "error",
      "quotes": ["error", "double"],
      "semi": ["error", "always"],
    },
  },
];
