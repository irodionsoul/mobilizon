module.exports = {
  root: true,

  env: {
    node: true,
  },

  extends: [
    "plugin:vue/essential",
    "@vue/airbnb",
    "@vue/typescript/recommended",
    "plugin:cypress/recommended",
    "plugin:prettier/recommended",
    "prettier",
    "eslint:recommended",
    "@vue/prettier",
    "@vue/prettier/@typescript-eslint",
  ],

  plugins: ["prettier"],

  parserOptions: {
    ecmaVersion: 2020,
  },

  rules: {
    "no-console": process.env.NODE_ENV === "production" ? "warn" : "off",
    "no-debugger": process.env.NODE_ENV === "production" ? "warn" : "off",
    "no-underscore-dangle": [
      "error",
      {
        allow: ["__typename"],
      },
    ],
    "@typescript-eslint/no-explicit-any": "off",
    "cypress/no-unnecessary-waiting": "off",
    "vue/max-len": [
      "error",
      {
        ignoreStrings: true,
        template: 170,
        code: 100,
      },
    ],
    "prettier/prettier": "error",
    "@typescript-eslint/interface-name-prefix": "off",
    "@typescript-eslint/no-use-before-define": "off",
    "import/prefer-default-export": "off",
  },

  ignorePatterns: ["src/typings/*.d.ts", "vue.config.js"],

  overrides: [{
    files: ["**/__tests__/*.{j,t}s?(x)", "**/tests/unit/**/*.spec.{j,t}s?(x)"],
    env: {
      mocha: true,
    },
  }],
};
