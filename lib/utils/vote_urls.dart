const voteIndexUrl = 'https://aps-staff.ntut.edu.tw/vote/index.jsp?op=Vote';

Uri voteCallbackUrl(String code) {
  return .parse(
    'https://aps-staff.ntut.edu.tw/vote/callback.jsp?oauthServer=http%3A%2F%2Fapp.ntut.edu.tw&code=$code&redirect_uri=https%3A%2F%2Faps-staff.ntut.edu.tw%2Fvote%2Fcallback.jsp',
  );
}

Uri voteIndexUri() => .parse(voteIndexUrl);
