# Next — como instalar no iPhone 6s sem usar um Mac

Você vai usar o **GitHub** pra compilar o app na nuvem (de graça) e o **Sideloadly** no seu PC Windows pra instalar o resultado no iPhone.

## Parte 1 — Compilar o app na nuvem (GitHub Actions)

1. Crie uma conta grátis em https://github.com (se ainda não tiver).
2. Crie um repositório novo (pode ser privado), ex: `next-app`.
3. Suba todos os arquivos desta pasta pro repositório — o jeito mais fácil é pela própria interface web do GitHub: abra o repositório, clique em **Add file > Upload files**, arraste tudo (incluindo a pasta `.github` e `Next`) e confirme (**Commit changes**).
   - ⚠️ A pasta `.github/workflows/build.yml` é essencial — é ela que manda compilar.
4. Vá na aba **Actions** do repositório. Deve aparecer um workflow chamado "Build Next IPA" rodando sozinho (ele dispara automaticamente ao subir os arquivos). Se não rodar, clique nele e depois em **Run workflow**.
5. Espere uns 3-5 minutos até o ícone ficar verde (✅).
6. Clique na execução concluída, desça até **Artifacts** e baixe o arquivo **Next-ipa** (é um `.zip` que contém o `Next.ipa` dentro).

## Parte 2 — Instalar no iPhone (Sideloadly, no Windows)

1. Baixe o Sideloadly: https://sideloadly.io (versão Windows).
2. Instale também o **iTunes** (versão do site da Apple, não da Microsoft Store) — o Sideloadly precisa dele pra reconhecer o iPhone.
3. Conecte o iPhone 6s no PC via cabo USB e toque em **Confiar** no iPhone quando aparecer o aviso.
4. Abra o Sideloadly, arraste o arquivo `Next.ipa` pra dentro da janela.
5. No campo Apple ID, digite seu Apple ID (pode ser o mesmo do iPhone). Recomendo usar um Apple ID qualquer (pode criar um novo, grátis, só pra isso).
6. Clique em **Start**. Ele vai pedir a senha do Apple ID e (se tiver 2FA) o código de verificação.
7. Aguarde — ele assina e instala o app sozinho.
8. No iPhone, vá em **Ajustes > Geral > VPN e Gerenciamento de Dispositivo** e toque em **Confiar** no seu Apple ID/desenvolvedor.
9. Abra o app "Next" na tela inicial e aceite a permissão de notificações quando pedir.

## ⚠️ Detalhe importante: expira a cada 7 dias

Contas Apple ID grátis fazem o app "expirar" depois de 7 dias — ele some da tela e você precisa repetir só a **Parte 2** (não precisa recompilar, o mesmo `Next.ipa` serve de novo). O Sideloadly tem uma opção de **auto-refresh** que pode fazer isso sozinho enquanto o PC estiver ligado e na mesma rede Wi-Fi do iPhone — vale ativar em **Settings** dentro do Sideloadly.

Se isso incomodar muito, a alternativa é pagar a conta Apple Developer (US$99/ano), que estende a validade pra 1 ano — mas pra uso pessoal o ciclo de 7 dias costuma ser tranquilo de manter.

## Como o app funciona

- Toque no **+** pra cadastrar uma tarefa (nome + horário). Ela repete todo dia nesse horário.
- Na hora, o app manda notificação a cada 5 minutos (por até 3h) com os botões **Iniciar / Adiar / Pular** direto na notificação.
- **Iniciar** abre o cronômetro. **Concluir** mostra automaticamente a próxima tarefa pendente.
- **Pular** marca como feita por hoje (volta amanhã). **Adiar** só silencia o lembrete atual.
- Tudo salvo localmente num arquivo JSON no próprio iPhone — sem login, sem nuvem, sem banco de dados.
