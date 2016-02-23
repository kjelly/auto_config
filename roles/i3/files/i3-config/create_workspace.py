#!/usr/bin/env python3
import i3


def main():
    workspaces = i3.get_workspaces()
    workspace_num_list = []
    for i in workspaces:
        workspace_num_list.append(i['num'])
    print(workspace_num_list)
    for num in  range(1, 100):
        if num not in workspace_num_list:
            i3.workspace(str(num))
            break


if __name__ == '__main__':
    main()

