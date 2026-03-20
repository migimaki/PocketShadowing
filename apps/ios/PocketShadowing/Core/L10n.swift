//
//  L10n.swift
//  PocketShadowing
//
//  Localization strings for all supported languages
//

import Foundation

enum L10n {
    private static var lang: String {
        UserDefaults.standard.string(forKey: "nativeLanguage") ?? "en"
    }

    private static func tr(_ table: [String: String]) -> String {
        table[lang] ?? table["en"]!
    }

    // MARK: - Common

    static var ok: String { tr([
        "en": "OK",
        "ja": "OK",
        "fr": "OK",
        "zh-Hans": "好的",
        "zh-Hant": "好的",
        "ko": "확인",
        "es": "OK"
    ])}

    static var error: String { tr([
        "en": "Error",
        "ja": "エラー",
        "fr": "Erreur",
        "zh-Hans": "错误",
        "zh-Hant": "錯誤",
        "ko": "오류",
        "es": "Error"
    ])}

    static var cancel: String { tr([
        "en": "Cancel",
        "ja": "キャンセル",
        "fr": "Annuler",
        "zh-Hans": "取消",
        "zh-Hant": "取消",
        "ko": "취소",
        "es": "Cancelar"
    ])}

    static var done: String { tr([
        "en": "Done",
        "ja": "完了",
        "fr": "Terminé",
        "zh-Hans": "完成",
        "zh-Hant": "完成",
        "ko": "완료",
        "es": "Listo"
    ])}

    static var settings: String { tr([
        "en": "Settings",
        "ja": "設定",
        "fr": "Paramètres",
        "zh-Hans": "设置",
        "zh-Hant": "設定",
        "ko": "설정",
        "es": "Ajustes"
    ])}

    static var loading: String { tr([
        "en": "Loading...",
        "ja": "読み込み中...",
        "fr": "Chargement...",
        "zh-Hans": "加载中...",
        "zh-Hant": "載入中...",
        "ko": "로딩 중...",
        "es": "Cargando..."
    ])}

    static var refresh: String { tr([
        "en": "Refresh",
        "ja": "更新",
        "fr": "Actualiser",
        "zh-Hans": "刷新",
        "zh-Hant": "重新整理",
        "ko": "새로고침",
        "es": "Actualizar"
    ])}

    // MARK: - Welcome

    static var continueWithGoogle: String { tr([
        "en": "Continue with Google",
        "ja": "Googleで続ける",
        "fr": "Continuer avec Google",
        "zh-Hans": "使用Google继续",
        "zh-Hant": "使用Google繼續",
        "ko": "Google로 계속하기",
        "es": "Continuar con Google"
    ])}

    static var continueWithApple: String { tr([
        "en": "Continue with Apple",
        "ja": "Appleで続ける",
        "fr": "Continuer avec Apple",
        "zh-Hans": "使用Apple继续",
        "zh-Hant": "使用Apple繼續",
        "ko": "Apple로 계속하기",
        "es": "Continuar con Apple"
    ])}

    static var signInWithEmail: String { tr([
        "en": "Sign in with Email",
        "ja": "メールでサインイン",
        "fr": "Se connecter par e-mail",
        "zh-Hans": "使用邮箱登录",
        "zh-Hant": "使用電子郵件登入",
        "ko": "이메일로 로그인",
        "es": "Iniciar sesión con correo"
    ])}

    static var dontHaveAccount: String { tr([
        "en": "Don't have an account?",
        "ja": "アカウントをお持ちでないですか？",
        "fr": "Vous n'avez pas de compte ?",
        "zh-Hans": "没有账户？",
        "zh-Hant": "沒有帳戶？",
        "ko": "계정이 없으신가요?",
        "es": "¿No tienes cuenta?"
    ])}

    static var signUp: String { tr([
        "en": "Sign Up",
        "ja": "新規登録",
        "fr": "S'inscrire",
        "zh-Hans": "注册",
        "zh-Hant": "註冊",
        "ko": "회원가입",
        "es": "Registrarse"
    ])}

    // MARK: - Email Auth

    static var createAccount: String { tr([
        "en": "Create Account",
        "ja": "アカウント作成",
        "fr": "Créer un compte",
        "zh-Hans": "创建账户",
        "zh-Hant": "建立帳戶",
        "ko": "계정 만들기",
        "es": "Crear cuenta"
    ])}

    static var signIn: String { tr([
        "en": "Sign In",
        "ja": "サインイン",
        "fr": "Se connecter",
        "zh-Hans": "登录",
        "zh-Hant": "登入",
        "ko": "로그인",
        "es": "Iniciar sesión"
    ])}

    static var email: String { tr([
        "en": "Email",
        "ja": "メールアドレス",
        "fr": "E-mail",
        "zh-Hans": "邮箱",
        "zh-Hant": "電子郵件",
        "ko": "이메일",
        "es": "Correo electrónico"
    ])}

    static var password: String { tr([
        "en": "Password",
        "ja": "パスワード",
        "fr": "Mot de passe",
        "zh-Hans": "密码",
        "zh-Hant": "密碼",
        "ko": "비밀번호",
        "es": "Contraseña"
    ])}

    static var alreadyHaveAccount: String { tr([
        "en": "Already have an account? Sign In",
        "ja": "アカウントをお持ちですか？サインイン",
        "fr": "Vous avez déjà un compte ? Se connecter",
        "zh-Hans": "已有账户？登录",
        "zh-Hant": "已有帳戶？登入",
        "ko": "이미 계정이 있으신가요? 로그인",
        "es": "¿Ya tienes cuenta? Iniciar sesión"
    ])}

    static var dontHaveAccountSignUp: String { tr([
        "en": "Don't have an account? Sign Up",
        "ja": "アカウントをお持ちでないですか？新規登録",
        "fr": "Vous n'avez pas de compte ? S'inscrire",
        "zh-Hans": "没有账户？注册",
        "zh-Hant": "沒有帳戶？註冊",
        "ko": "계정이 없으신가요? 회원가입",
        "es": "¿No tienes cuenta? Registrarse"
    ])}

    // MARK: - Onboarding

    static var onboardingTitle1: String { tr([
        "en": "Listen & Shadow",
        "ja": "聞いてシャドーイング",
        "fr": "Écouter et répéter",
        "zh-Hans": "听力与跟读",
        "zh-Hant": "聽力與跟讀",
        "ko": "듣기 & 섀도잉",
        "es": "Escucha y repite"
    ])}

    static var onboardingDesc1: String { tr([
        "en": "Listen to native English speakers and practice speaking along with them. Your voice is recognized in real-time to help you improve.",
        "ja": "ネイティブの英語を聞いて、一緒に話す練習をしましょう。リアルタイムの音声認識であなたの上達をサポートします。",
        "fr": "Écoutez des locuteurs natifs anglais et entraînez-vous à parler avec eux. Votre voix est reconnue en temps réel pour vous aider à progresser.",
        "zh-Hans": "聆听英语母语者的发音，跟着一起练习口语。实时语音识别帮助你不断进步。",
        "zh-Hant": "聆聽英語母語者的發音，跟著一起練習口說。即時語音辨識幫助你不斷進步。",
        "ko": "원어민의 영어를 듣고 따라 말하는 연습을 하세요. 실시간 음성 인식으로 실력 향상을 도와드립니다.",
        "es": "Escucha a hablantes nativos de inglés y practica hablando con ellos. Tu voz se reconoce en tiempo real para ayudarte a mejorar."
    ])}

    static var onboardingTitle2: String { tr([
        "en": "Track Your Progress",
        "ja": "進捗を確認",
        "fr": "Suivez vos progrès",
        "zh-Hans": "追踪你的进步",
        "zh-Hant": "追蹤你的進步",
        "ko": "학습 진도 확인",
        "es": "Sigue tu progreso"
    ])}

    static var onboardingDesc2: String { tr([
        "en": "Get accuracy and speed scores for each practice session. Beat your best scores and watch your English improve over time.",
        "ja": "各練習セッションの正確さとスピードのスコアを確認。自己ベストを更新して、英語力の向上を実感しましょう。",
        "fr": "Obtenez des scores de précision et de vitesse pour chaque session. Battez vos meilleurs scores et observez vos progrès en anglais.",
        "zh-Hans": "每次练习都会获得准确度和速度评分。不断刷新最佳成绩，见证你的英语进步。",
        "zh-Hant": "每次練習都會獲得準確度和速度評分。不斷刷新最佳成績，見證你的英語進步。",
        "ko": "각 연습 세션의 정확도와 속도 점수를 확인하세요. 최고 점수를 갱신하며 영어 실력의 향상을 느껴보세요.",
        "es": "Obtén puntuaciones de precisión y velocidad en cada sesión. Supera tus mejores marcas y observa cómo mejora tu inglés."
    ])}

    static var onboardingTitle3: String { tr([
        "en": "Learn Anywhere",
        "ja": "いつでもどこでも学習",
        "fr": "Apprenez partout",
        "zh-Hans": "随时随地学习",
        "zh-Hant": "隨時隨地學習",
        "ko": "언제 어디서나 학습",
        "es": "Aprende en cualquier lugar"
    ])}

    static var onboardingDesc3: String { tr([
        "en": "Practice English shadowing anytime, anywhere. Choose from a variety of channels and lessons to match your interests.",
        "ja": "いつでもどこでも英語のシャドーイングを練習。豊富なチャンネルとレッスンから、興味に合わせて選べます。",
        "fr": "Pratiquez le shadowing en anglais à tout moment. Choisissez parmi une variété de chaînes et de leçons selon vos centres d'intérêt.",
        "zh-Hans": "随时随地练习英语跟读。从丰富的频道和课程中选择你感兴趣的内容。",
        "zh-Hant": "隨時隨地練習英語跟讀。從豐富的頻道和課程中選擇你感興趣的內容。",
        "ko": "언제 어디서나 영어 섀도잉을 연습하세요. 다양한 채널과 레슨 중 관심 있는 것을 선택할 수 있습니다.",
        "es": "Practica el shadowing en inglés en cualquier momento y lugar. Elige entre una variedad de canales y lecciones según tus intereses."
    ])}

    static var getStarted: String { tr([
        "en": "Get Started",
        "ja": "始める",
        "fr": "Commencer",
        "zh-Hans": "开始使用",
        "zh-Hant": "開始使用",
        "ko": "시작하기",
        "es": "Empezar"
    ])}

    static var next: String { tr([
        "en": "Next",
        "ja": "次へ",
        "fr": "Suivant",
        "zh-Hans": "下一步",
        "zh-Hant": "下一步",
        "ko": "다음",
        "es": "Siguiente"
    ])}

    // MARK: - Channels

    static var channels: String { tr([
        "en": "Channels",
        "ja": "チャンネル",
        "fr": "Chaînes",
        "zh-Hans": "频道",
        "zh-Hant": "頻道",
        "ko": "채널",
        "es": "Canales"
    ])}

    static var loadingChannels: String { tr([
        "en": "Loading channels...",
        "ja": "チャンネルを読み込み中...",
        "fr": "Chargement des chaînes...",
        "zh-Hans": "加载频道中...",
        "zh-Hant": "載入頻道中...",
        "ko": "채널 로딩 중...",
        "es": "Cargando canales..."
    ])}

    static var noChannels: String { tr([
        "en": "No Channels",
        "ja": "チャンネルなし",
        "fr": "Aucune chaîne",
        "zh-Hans": "没有频道",
        "zh-Hant": "沒有頻道",
        "ko": "채널 없음",
        "es": "Sin canales"
    ])}

    static var noChannelsAvailable: String { tr([
        "en": "No English channels available.",
        "ja": "利用可能な英語チャンネルがありません。",
        "fr": "Aucune chaîne en anglais disponible.",
        "zh-Hans": "没有可用的英语频道。",
        "zh-Hant": "沒有可用的英語頻道。",
        "ko": "이용 가능한 영어 채널이 없습니다.",
        "es": "No hay canales en inglés disponibles."
    ])}

    static var myChannels: String { tr([
        "en": "My Channels",
        "ja": "マイチャンネル",
        "fr": "Mes chaînes",
        "zh-Hans": "我的频道",
        "zh-Hant": "我的頻道",
        "ko": "내 채널",
        "es": "Mis canales"
    ])}

    static var beginner: String { tr([
        "en": "Beginner",
        "ja": "初級",
        "fr": "Débutant",
        "zh-Hans": "初级",
        "zh-Hant": "初級",
        "ko": "초급",
        "es": "Principiante"
    ])}

    static var intermediate: String { tr([
        "en": "Intermediate",
        "ja": "中級",
        "fr": "Intermédiaire",
        "zh-Hans": "中级",
        "zh-Hant": "中級",
        "ko": "중급",
        "es": "Intermedio"
    ])}

    static var noChannelsFollowed: String { tr([
        "en": "No channels followed yet.",
        "ja": "まだフォローしているチャンネルはありません。",
        "fr": "Aucune chaîne suivie pour le moment.",
        "zh-Hans": "还没有关注任何频道。",
        "zh-Hant": "還沒有關注任何頻道。",
        "ko": "아직 팔로우한 채널이 없습니다.",
        "es": "Aún no sigues ningún canal."
    ])}

    static var comingSoon: String { tr([
        "en": "Coming soon.",
        "ja": "近日公開。",
        "fr": "Bientôt disponible.",
        "zh-Hans": "即将推出。",
        "zh-Hant": "即將推出。",
        "ko": "곧 출시 예정.",
        "es": "Próximamente."
    ])}

    // MARK: - Lessons

    static var following: String { tr([
        "en": "Following",
        "ja": "フォロー中",
        "fr": "Suivi",
        "zh-Hans": "已关注",
        "zh-Hant": "已關注",
        "ko": "팔로잉",
        "es": "Siguiendo"
    ])}

    static var follow: String { tr([
        "en": "Follow",
        "ja": "フォロー",
        "fr": "Suivre",
        "zh-Hans": "关注",
        "zh-Hant": "關注",
        "ko": "팔로우",
        "es": "Seguir"
    ])}

    static var loadingLessons: String { tr([
        "en": "Loading lessons...",
        "ja": "レッスンを読み込み中...",
        "fr": "Chargement des leçons...",
        "zh-Hans": "加载课程中...",
        "zh-Hant": "載入課程中...",
        "ko": "레슨 로딩 중...",
        "es": "Cargando lecciones..."
    ])}

    static var free: String { tr([
        "en": "FREE",
        "ja": "無料",
        "fr": "GRATUIT",
        "zh-Hans": "免费",
        "zh-Hant": "免費",
        "ko": "무료",
        "es": "GRATIS"
    ])}

    static var loadMore: String { tr([
        "en": "Load More",
        "ja": "もっと見る",
        "fr": "Charger plus",
        "zh-Hans": "加载更多",
        "zh-Hant": "載入更多",
        "ko": "더 보기",
        "es": "Cargar más"
    ])}

    static var noLessons: String { tr([
        "en": "No Lessons",
        "ja": "レッスンなし",
        "fr": "Aucune leçon",
        "zh-Hans": "没有课程",
        "zh-Hant": "沒有課程",
        "ko": "레슨 없음",
        "es": "Sin lecciones"
    ])}

    static func pullToRefresh(channelName: String) -> String { tr([
        "en": "Pull down to refresh to load lessons from \(channelName)",
        "ja": "下に引いて\(channelName)のレッスンを読み込む",
        "fr": "Tirez vers le bas pour charger les leçons de \(channelName)",
        "zh-Hans": "下拉刷新以加载\(channelName)的课程",
        "zh-Hant": "下拉重新整理以載入\(channelName)的課程",
        "ko": "아래로 당겨서 \(channelName)의 레슨을 불러오세요",
        "es": "Desliza hacia abajo para cargar lecciones de \(channelName)"
    ])}

    // MARK: - Settings

    static var myNativeLanguage: String { tr([
        "en": "My native language",
        "ja": "母国語",
        "fr": "Ma langue maternelle",
        "zh-Hans": "我的母语",
        "zh-Hant": "我的母語",
        "ko": "모국어",
        "es": "Mi idioma nativo"
    ])}

    static var signOut: String { tr([
        "en": "Sign Out",
        "ja": "サインアウト",
        "fr": "Se déconnecter",
        "zh-Hans": "退出登录",
        "zh-Hant": "登出",
        "ko": "로그아웃",
        "es": "Cerrar sesión"
    ])}

    // MARK: - Subscription

    static var subscription: String { tr([
        "en": "Subscription",
        "ja": "サブスクリプション",
        "fr": "Abonnement",
        "zh-Hans": "订阅",
        "zh-Hant": "訂閱",
        "ko": "구독",
        "es": "Suscripción"
    ])}

    static var active: String { tr([
        "en": "Active",
        "ja": "有効",
        "fr": "Actif",
        "zh-Hans": "已激活",
        "zh-Hant": "已啟用",
        "ko": "활성",
        "es": "Activo"
    ])}

    static var premium: String { tr([
        "en": "Premium",
        "ja": "プレミアム",
        "fr": "Premium",
        "zh-Hans": "高级版",
        "zh-Hant": "進階版",
        "ko": "프리미엄",
        "es": "Premium"
    ])}

    static var subscribeButton: String { tr([
        "en": "Subscribe",
        "ja": "登録する",
        "fr": "S'abonner",
        "zh-Hans": "订阅",
        "zh-Hant": "訂閱",
        "ko": "구독하기",
        "es": "Suscribirse"
    ])}

    static var restorePurchases: String { tr([
        "en": "Restore Purchases",
        "ja": "購入を復元",
        "fr": "Restaurer les achats",
        "zh-Hans": "恢复购买",
        "zh-Hant": "恢復購買",
        "ko": "구매 복원",
        "es": "Restaurar compras"
    ])}

    static var alreadySubscribed: String { tr([
        "en": "You are a Premium member",
        "ja": "プレミアムメンバーです",
        "fr": "Vous êtes membre Premium",
        "zh-Hans": "您是高级会员",
        "zh-Hant": "您是進階會員",
        "ko": "프리미엄 회원입니다",
        "es": "Eres miembro Premium"
    ])}

    static var subscriptionFeature1: String { tr([
        "en": "Unlock all lessons",
        "ja": "すべてのレッスンをアンロック",
        "fr": "Débloquer toutes les leçons",
        "zh-Hans": "解锁所有课程",
        "zh-Hant": "解鎖所有課程",
        "ko": "모든 레슨 잠금 해제",
        "es": "Desbloquea todas las lecciones"
    ])}

    static var subscriptionFeature2: String { tr([
        "en": "Access all channels",
        "ja": "すべてのチャンネルにアクセス",
        "fr": "Accéder à toutes les chaînes",
        "zh-Hans": "访问所有频道",
        "zh-Hant": "存取所有頻道",
        "ko": "모든 채널 이용",
        "es": "Accede a todos los canales"
    ])}

    static var subscriptionFeature3: String { tr([
        "en": "New content every week",
        "ja": "毎週新しいコンテンツ",
        "fr": "Nouveau contenu chaque semaine",
        "zh-Hans": "每周更新内容",
        "zh-Hant": "每週更新內容",
        "ko": "매주 새로운 콘텐츠",
        "es": "Contenido nuevo cada semana"
    ])}

    static var purchaseFailed: String { tr([
        "en": "Purchase failed. Please try again.",
        "ja": "購入に失敗しました。もう一度お試しください。",
        "fr": "L'achat a échoué. Veuillez réessayer.",
        "zh-Hans": "购买失败，请重试。",
        "zh-Hant": "購買失敗，請重試。",
        "ko": "구매에 실패했습니다. 다시 시도해 주세요.",
        "es": "La compra ha fallado. Inténtalo de nuevo."
    ])}

    static var perMonth: String { tr([
        "en": "/ month",
        "ja": "/ 月",
        "fr": "/ mois",
        "zh-Hans": "/ 月",
        "zh-Hant": "/ 月",
        "ko": "/ 월",
        "es": "/ mes"
    ])}

    // MARK: - Player

    static var noSentencesAvailable: String { tr([
        "en": "No sentences available",
        "ja": "文章がありません",
        "fr": "Aucune phrase disponible",
        "zh-Hans": "没有可用的句子",
        "zh-Hant": "沒有可用的句子",
        "ko": "사용 가능한 문장이 없습니다",
        "es": "No hay frases disponibles"
    ])}

    static var slideToUnlock: String { tr([
        "en": "Slide to unlock",
        "ja": "スライドしてロック解除",
        "fr": "Glissez pour déverrouiller",
        "zh-Hans": "滑动解锁",
        "zh-Hant": "滑動解鎖",
        "ko": "밀어서 잠금 해제",
        "es": "Desliza para desbloquear"
    ])}

    static var loop: String { tr([
        "en": "Loop",
        "ja": "ループ",
        "fr": "Boucle",
        "zh-Hans": "循环",
        "zh-Hant": "循環",
        "ko": "반복",
        "es": "Bucle"
    ])}

    // MARK: - Completion

    static var lessonComplete: String { tr([
        "en": "Lesson Complete!",
        "ja": "レッスン完了！",
        "fr": "Leçon terminée !",
        "zh-Hans": "课程完成！",
        "zh-Hant": "課程完成！",
        "ko": "레슨 완료!",
        "es": "¡Lección completada!"
    ])}

    static var accuracy: String { tr([
        "en": "Accuracy",
        "ja": "正確さ",
        "fr": "Précision",
        "zh-Hans": "准确度",
        "zh-Hant": "準確度",
        "ko": "정확도",
        "es": "Precisión"
    ])}

    static var speed: String { tr([
        "en": "Speed",
        "ja": "スピード",
        "fr": "Vitesse",
        "zh-Hans": "速度",
        "zh-Hant": "速度",
        "ko": "속도",
        "es": "Velocidad"
    ])}

    static func bestScore(_ score: Int) -> String { tr([
        "en": "Best: \(score)",
        "ja": "ベスト: \(score)",
        "fr": "Meilleur : \(score)",
        "zh-Hans": "最佳: \(score)",
        "zh-Hant": "最佳: \(score)",
        "ko": "최고: \(score)",
        "es": "Mejor: \(score)"
    ])}

    static var newBestScore: String { tr([
        "en": "New Best Score!",
        "ja": "新記録！",
        "fr": "Nouveau record !",
        "zh-Hans": "新最佳成绩！",
        "zh-Hant": "新最佳成績！",
        "ko": "새로운 최고 점수!",
        "es": "¡Nueva mejor puntuación!"
    ])}

    static var tryAgain: String { tr([
        "en": "Try Again",
        "ja": "もう一度",
        "fr": "Réessayer",
        "zh-Hans": "再试一次",
        "zh-Hant": "再試一次",
        "ko": "다시 시도",
        "es": "Intentar de nuevo"
    ])}

    static var close: String { tr([
        "en": "Close",
        "ja": "閉じる",
        "fr": "Fermer",
        "zh-Hans": "关闭",
        "zh-Hant": "關閉",
        "ko": "닫기",
        "es": "Cerrar"
    ])}
}
