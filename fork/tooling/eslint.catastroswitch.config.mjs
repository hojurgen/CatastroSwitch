import tseslint from 'typescript-eslint';

const defaultFiles = [
  'src/vs/**/catastroswitch/**/*.ts',
  'src/vs/**/*CatastroSwitch*.ts',
  'extensions/catastroswitch/**/*.ts',
  'test/**/catastroswitch/**/*.ts'
];

export function createCatastroSwitchTypeScriptPolicy({
  files = defaultFiles,
  tsconfigRootDir = process.cwd()
} = {}) {
  return tseslint.config({
    name: 'catastroswitch/typescript-policy',
    files,
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir
      }
    },
    rules: {
      curly: ['error', 'all'],
      'prefer-arrow-callback': 'error',
      '@typescript-eslint/consistent-type-imports': [
        'error',
        {
          prefer: 'type-imports',
          fixStyle: 'inline-type-imports'
        }
      ],
      '@typescript-eslint/naming-convention': [
        'error',
        {
          selector: 'typeLike',
          format: ['PascalCase']
        },
        {
          selector: 'interface',
          format: ['PascalCase'],
          custom: {
            regex: '^I[A-Z]',
            match: false
          }
        },
        {
          selector: 'enumMember',
          format: ['PascalCase']
        },
        {
          selector: 'function',
          format: ['camelCase']
        },
        {
          selector: 'method',
          format: ['camelCase']
        },
        {
          selector: 'parameter',
          format: ['camelCase'],
          leadingUnderscore: 'forbid'
        },
        {
          selector: 'property',
          format: ['camelCase'],
          leadingUnderscore: 'forbid'
        },
        {
          selector: 'variable',
          format: ['camelCase', 'UPPER_CASE'],
          leadingUnderscore: 'forbid'
        }
      ],
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/no-misused-promises': [
        'error',
        {
          checksVoidReturn: {
            arguments: false,
            attributes: false
          }
        }
      ],
      '@typescript-eslint/no-unsafe-argument': 'error',
      '@typescript-eslint/no-unsafe-assignment': 'error',
      '@typescript-eslint/no-unsafe-call': 'error',
      '@typescript-eslint/no-unsafe-member-access': 'error',
      '@typescript-eslint/no-unsafe-return': 'error',
      '@typescript-eslint/only-throw-error': 'error',
      '@typescript-eslint/switch-exhaustiveness-check': 'error',
      '@typescript-eslint/use-unknown-in-catch-callback-variable': 'error'
    }
  });
}

export default createCatastroSwitchTypeScriptPolicy();
