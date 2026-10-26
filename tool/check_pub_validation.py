"""Allow only Pub's optional homepage/repository recommendation; fail closed."""
import re
import sys
from pathlib import Path


def main():
    status = int(sys.argv[1])
    if status == 0:
        return 0
    output = Path(sys.argv[2]).read_text()
    recommendation = (
        'It\'s strongly recommended to include a "homepage" or "repository" '
        'field in your pubspec.yaml'
    )
    issues = re.findall(r'^\* (.*)$', output, re.MULTILINE)
    # Exit 65 alone is insufficient: it can also indicate invalid package data.
    # Require both summaries and exactly the one known recommendation. Changes
    # to Pub's diagnostic format must be reviewed rather than silently accepted.
    if (
        status == 65
        and issues == [recommendation]
        and re.search(r'^Package validation found the following (?:1 )?potential issue[s]?:$',
                      output, re.MULTILINE)
        and re.search(r'^Package has 1 warning[s]?\.$', output, re.MULTILINE)
        and not re.search(r'\b(?:error|errors)\b', output, re.IGNORECASE)
    ):
        print('提示：homepage / repository 暂未填写，不阻止发布。')
        return 0
    print('发布预检失败：存在未获豁免的问题，停止上传。', file=sys.stderr)
    return status or 1


if __name__ == '__main__':
    sys.exit(main())
