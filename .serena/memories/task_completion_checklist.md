# Checklist de Completação de Tarefas

## Antes de Considerar uma Tarefa "Completa"

### 1. Verificação Funcional
- [ ] Testar manualmente a funcionalidade implementada
- [ ] Verificar se não há erros visuais ou de execução
- [ ] Confirmar que o comportamento corresponde ao esperado

### 2. Formatação
- [ ] Arquivos Terraform estão formatados (`terraform fmt`)
- [ ] Arquivos YAML estão formatados (`yq --prettyPrint`)
- [ ] Scripts Shell estão formatados (`shfmt -i 2 -ci`)

### 3. Git
- [ ] Arquivos modificados estão no stage correto
- [ ] Mensagem de commit segue o padrão `tipo: descrição`
- [ ] Branch está atualizada com main (se necessário)

### 4. Segurança
- [ ] Nenhum segredo ou credencial foi commitado
- [ ] Arquivos `.env` estão em `.gitignore`
- [ ] Tokens e chaves estão em variáveis de ambiente

### 5. Documentação
- [ ] README ou documentação relevante foi atualizada
- [ ] Comentários em código explicam "por que" não "o que"
- [ ] Mudanças significativas foram documentadas

## Comandos Finais

```bash
# Verificar tudo antes de commit
git status
git diff --staged

# Fazer commit
git commit -m "tipo: descrição"

# Push (após confirmação)
git push origin feature/nome-da-feature
```

## Após Merge

- [ ] Deletar branch local e remota
- [ ] Atualizar documentação se necessário
- [ ] Comemorar 🎉
