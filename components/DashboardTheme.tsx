'use client';

export default function DashboardTheme() {
  return <style>{`
    .main { display:flex; flex-direction:column; }
    .main > .top { order:0; }
    .main > #dashboard { order:1; margin-top:0 !important; }
    .main > #accounts { order:2; }
    .main > #attacks { order:3; }
    .main > #bot-protection { order:4; }
    .main > #scripts { order:5; }
    .main > #settings { order:6; }
    .main > #network { order:7; }

    #dashboard { position:relative; }
    #dashboard:before {
      content:'ODIN COMMAND CENTER';
      display:block;
      margin:0 0 12px 2px;
      font-size:11px;
      font-weight:900;
      letter-spacing:.14em;
      color:#64748b;
    }
    #dashboard .card {
      position:relative;
      overflow:hidden;
      min-height:128px;
      padding:20px;
      border-color:#dbe2ea;
      box-shadow:0 8px 24px rgba(15,23,42,.055);
      transition:transform .16s ease,box-shadow .16s ease,border-color .16s ease;
    }
    #dashboard .card:after {
      content:'⚔';
      position:absolute;
      right:15px;
      top:9px;
      font-size:44px;
      opacity:.045;
      transform:rotate(-12deg);
      pointer-events:none;
    }
    #dashboard .card:hover {
      transform:translateY(-2px);
      box-shadow:0 13px 30px rgba(15,23,42,.09);
      border-color:#cbd5e1;
    }
    #dashboard .muted:first-child {
      font-size:11px;
      font-weight:850;
      letter-spacing:.08em;
      text-transform:uppercase;
    }
    #dashboard .metric { font-size:36px; letter-spacing:-.04em; }
    #dashboard .card:nth-child(2) .metric { color:#15803d; }
    #dashboard .card:nth-child(3) .metric { color:#b91c1c; }
    #dashboard .card:nth-child(4) .metric { color:#a16207; }

    #accounts.card {
      box-shadow:0 10px 28px rgba(15,23,42,.045);
    }
    #accounts .sectionhead h2:before { content:'⚔'; margin-right:9px; font-size:15px; opacity:.65; }
    #attacks .sectionhead h2:before { content:'🗡️'; margin-right:9px; font-size:15px; }
    #bot-protection .sectionhead h2:before { content:'🛡️'; margin-right:9px; font-size:15px; }
    #scripts .sectionhead h2:before { content:'🧩'; margin-right:9px; font-size:15px; }
    #settings .sectionhead h2:before { content:'⚙️'; margin-right:9px; font-size:15px; }
    #network .sectionhead h2:before { content:'🌐'; margin-right:9px; font-size:15px; }

    .top .title { font-weight:900; letter-spacing:-.035em; }
    .sidebar { box-shadow:10px 0 30px rgba(15,23,42,.08); }
    .brand { letter-spacing:-.02em; }
    .nav a { transition:background .15s ease,color .15s ease,transform .15s ease; }
    .nav a:hover { transform:translateX(2px); }

    @media(max-width:900px){
      #dashboard:before { margin-bottom:9px; }
      #dashboard .card { min-height:112px; padding:15px; }
      #dashboard .metric { font-size:30px; }
    }
    @media(max-width:600px){
      #dashboard .card { min-height:104px; }
      #dashboard .metric { font-size:27px; }
      #dashboard .card:after { font-size:35px; }
    }
  `}</style>;
}
