# encoding: utf-8
module EventHandlers  
  # When a comment is created
  def handle_comment_created_event(payload)
    repo = payload['repository']['full_name']
    issue_number = payload['issue']['number']
    commenter = payload['comment']['user']['login']
    # Add a comment after other user's comments
    if commenter != 'remindabot[bot]'
      @installation_client.add_comment(repo, issue_number, 'You comment, I comment.')
    end
  end

  # When a comment is deleted
  def handle_comment_deleted_event(payload)
    logger.info('A comment was deleted!')
  end
end
